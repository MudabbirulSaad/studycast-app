import 'package:flutter_test/flutter_test.dart';
import 'package:studycast/application/generate_podcast_workflow.dart';
import 'package:studycast/application/job_service.dart';
import 'package:studycast/application/project_service.dart';
import 'package:studycast/application/script_service.dart';
import 'package:studycast/domain/api/api_failure.dart';
import 'package:studycast/domain/api/studycast_models.dart';

import 'fake_studycast_backend.dart';

void main() {
  test(
    'creates a project, saves pasted script, submits job, and completes without audio download',
    () async {
      final project = _project();
      final script = _script();
      final submittedJob = _job(JobStatus.completed);
      final calls = <String>[];
      final events = <GeneratePodcastEventType>[];
      final backend = FakeStudycastBackend()
        ..onCreateProject = ({required title}) async {
          calls.add('create:$title');
          return project;
        }
        ..onSaveScript =
            ({required projectId, required text, required source}) async {
              calls.add('script:$projectId:$text:${source.name}');
              return script;
            }
        ..onSubmitJob = ({required projectId, options}) async {
          calls.add('submit:$projectId:${options?.voiceProfileId}');
          return submittedJob;
        };
      final workflow = GeneratePodcastWorkflow(
        projectService: ProjectService(backend),
        scriptService: ScriptService(backend),
        jobService: JobService(backend),
        delay: (_) async {},
      );

      final result = await workflow.generateFromPastedScript(
        GeneratePodcastRequest(
          projectTitle: 'Biology 101',
          scriptText: 'Host: Hello',
          jobOptions: const StartJobOptions(voiceProfileId: 'voice-1'),
        ),
        onEvent: (event) => events.add(event.type),
      );

      expect(result.project, same(project));
      expect(result.script, same(script));
      expect(result.finalJob, same(submittedJob));
      expect(result.outcome, GeneratePodcastOutcome.completed);
      expect(result.audioReady, isTrue);
      expect(result.failureReason, isNull);
      expect(calls, [
        'create:Biology 101',
        'script:project-1:Host: Hello:pasted',
        'submit:project-1:voice-1',
      ]);
      expect(events, [
        GeneratePodcastEventType.projectCreated,
        GeneratePodcastEventType.scriptSaved,
        GeneratePodcastEventType.jobSubmitted,
        GeneratePodcastEventType.completed,
      ]);
    },
  );

  test('polls queued or running jobs until completed', () async {
    final jobs = [
      _job(JobStatus.queued),
      _job(JobStatus.running, progressPercent: 50),
      _job(JobStatus.completed, progressPercent: 100),
    ];
    final polledStatuses = <JobStatus>[];
    var pollIndex = 0;
    final backend = FakeStudycastBackend()
      ..onCreateProject = ({required title}) async {
        return _project();
      }
      ..onSaveScript =
          ({required projectId, required text, required source}) async {
            return _script();
          }
      ..onSubmitJob = ({required projectId, options}) async {
        return jobs.first;
      }
      ..onGetJob = (jobId) async {
        final job = jobs[++pollIndex];
        polledStatuses.add(job.status);
        return job;
      };
    final events = <GeneratePodcastEvent>[];
    final workflow = GeneratePodcastWorkflow(
      projectService: ProjectService(backend),
      scriptService: ScriptService(backend),
      jobService: JobService(backend),
      pollInterval: const Duration(milliseconds: 250),
      delay: (duration) async {
        expect(duration, const Duration(milliseconds: 250));
      },
    );

    final result = await workflow.generateFromPastedScript(
      const GeneratePodcastRequest(
        projectTitle: 'Biology 101',
        scriptText: 'Host: Hello',
      ),
      onEvent: events.add,
    );

    expect(result.outcome, GeneratePodcastOutcome.completed);
    expect(result.finalJob.status, JobStatus.completed);
    expect(polledStatuses, [JobStatus.running, JobStatus.completed]);
    expect(
      events
          .where((event) => event.type == GeneratePodcastEventType.jobPolled)
          .map((event) => event.job?.status),
      [JobStatus.running, JobStatus.completed],
    );
  });

  test(
    'returns unsuccessful outcomes for failed, cancelled, and interrupted jobs',
    () async {
      for (final status in [
        JobStatus.failed,
        JobStatus.cancelled,
        JobStatus.interrupted,
      ]) {
        final backend = FakeStudycastBackend()
          ..onCreateProject = ({required title}) async {
            return _project();
          }
          ..onSaveScript =
              ({required projectId, required text, required source}) async {
                return _script();
              }
          ..onSubmitJob = ({required projectId, options}) async {
            return _job(status, failureReason: 'Generation stopped');
          };
        final workflow = GeneratePodcastWorkflow(
          projectService: ProjectService(backend),
          scriptService: ScriptService(backend),
          jobService: JobService(backend),
          delay: (_) async {},
        );

        final result = await workflow.generateFromPastedScript(
          const GeneratePodcastRequest(
            projectTitle: 'Biology 101',
            scriptText: 'Host: Hello',
          ),
        );

        expect(result.audioReady, isFalse);
        expect(result.finalJob.status, status);
        expect(result.failureReason, 'Generation stopped');
        expect(result.outcome, switch (status) {
          JobStatus.failed => GeneratePodcastOutcome.failed,
          JobStatus.cancelled => GeneratePodcastOutcome.cancelled,
          JobStatus.interrupted => GeneratePodcastOutcome.interrupted,
          _ => throw StateError('Unexpected status'),
        });
      }
    },
  );

  test('lets service failures propagate', () async {
    const failure = ApiFailure(message: 'empty project title');
    final backend = FakeStudycastBackend()
      ..onCreateProject = ({required title}) async => throw failure;
    final workflow = GeneratePodcastWorkflow(
      projectService: ProjectService(backend),
      scriptService: ScriptService(backend),
      jobService: JobService(backend),
      delay: (_) async {},
    );

    await expectLater(
      workflow.generateFromPastedScript(
        const GeneratePodcastRequest(
          projectTitle: '',
          scriptText: 'Host: Hello',
        ),
      ),
      throwsA(same(failure)),
    );
  });
}

ProjectSummary _project() {
  return ProjectSummary(
    id: 'project-1',
    title: 'Biology 101',
    createdAt: DateTime.utc(2026, 6, 16),
    updatedAt: DateTime.utc(2026, 6, 16),
  );
}

Script _script() {
  return Script(
    projectId: 'project-1',
    text: 'Host: Hello',
    source: ScriptSource.pasted,
    speakers: const ['Host'],
    updatedAt: DateTime.utc(2026, 6, 16),
    chunks: const [Chunk(index: 0, speaker: 'Host', text: 'Hello')],
  );
}

Job _job(JobStatus status, {int progressPercent = 0, String? failureReason}) {
  return Job(
    id: 'job-1',
    projectId: 'project-1',
    status: status,
    phase: status == JobStatus.completed ? JobPhase.completed : JobPhase.queued,
    progressPercent: progressPercent,
    totalChunks: 1,
    completedChunks: status == JobStatus.completed ? 1 : 0,
    currentChunkIndex: null,
    currentChunkPreview: null,
    message: status.name,
    failureReason: failureReason,
    cancellationRequested: status == JobStatus.cancelRequested,
    createdAt: DateTime.utc(2026, 6, 16),
    startedAt: null,
    updatedAt: DateTime.utc(2026, 6, 16),
    completedAt: status == JobStatus.completed
        ? DateTime.utc(2026, 6, 16)
        : null,
    snapshot: null,
  );
}
