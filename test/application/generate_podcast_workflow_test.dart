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
    expect(result.finalJob?.status, JobStatus.completed);
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
        expect(result.finalJob?.status, status);
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

  test('can be cancelled before creating a project', () async {
    final cancellationToken = GeneratePodcastCancellationToken()..cancel();
    final backend = FakeStudycastBackend()
      ..onCreateProject = ({required title}) async {
        fail('project should not be created after cancellation');
      };
    final events = <GeneratePodcastEventType>[];
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
      cancellationToken: cancellationToken,
      onEvent: (event) => events.add(event.type),
    );

    expect(result.project, isNull);
    expect(result.script, isNull);
    expect(result.finalJob, isNull);
    expect(result.outcome, GeneratePodcastOutcome.cancelled);
    expect(result.audioReady, isFalse);
    expect(events, [
      GeneratePodcastEventType.cancellationRequested,
      GeneratePodcastEventType.cancelled,
    ]);
  });

  test('can be cancelled after creating a project', () async {
    final project = _project();
    final cancellationToken = GeneratePodcastCancellationToken();
    final backend = FakeStudycastBackend()
      ..onCreateProject = ({required title}) async {
        cancellationToken.cancel();
        return project;
      }
      ..onSaveScript =
          ({required projectId, required text, required source}) async {
            fail('script should not be saved after cancellation');
          }
      ..onCancelJob = (jobId) async {
        fail('backend cancel should not be called before job submission');
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
      cancellationToken: cancellationToken,
    );

    expect(result.project, same(project));
    expect(result.script, isNull);
    expect(result.finalJob, isNull);
    expect(result.outcome, GeneratePodcastOutcome.cancelled);
    expect(result.audioReady, isFalse);
  });

  test('can be cancelled after saving the script', () async {
    final project = _project();
    final script = _script();
    final cancellationToken = GeneratePodcastCancellationToken();
    final backend = FakeStudycastBackend()
      ..onCreateProject = ({required title}) async {
        return project;
      }
      ..onSaveScript =
          ({required projectId, required text, required source}) async {
            cancellationToken.cancel();
            return script;
          }
      ..onSubmitJob = ({required projectId, options}) async {
        fail('job should not be submitted after cancellation');
      }
      ..onCancelJob = (jobId) async {
        fail('backend cancel should not be called before job submission');
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
      cancellationToken: cancellationToken,
    );

    expect(result.project, same(project));
    expect(result.script, same(script));
    expect(result.finalJob, isNull);
    expect(result.outcome, GeneratePodcastOutcome.cancelled);
    expect(result.audioReady, isFalse);
  });

  test('cancels the backend job after submission', () async {
    final project = _project();
    final script = _script();
    final submittedJob = _job(JobStatus.queued);
    final cancelledJob = _job(JobStatus.cancelled);
    final cancellationToken = GeneratePodcastCancellationToken();
    final cancelledJobIds = <String>[];
    final events = <GeneratePodcastEventType>[];
    final backend = FakeStudycastBackend()
      ..onCreateProject = ({required title}) async {
        return project;
      }
      ..onSaveScript =
          ({required projectId, required text, required source}) async {
            return script;
          }
      ..onSubmitJob = ({required projectId, options}) async {
        cancellationToken.cancel();
        return submittedJob;
      }
      ..onCancelJob = (jobId) async {
        cancelledJobIds.add(jobId);
        return cancelledJob;
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
      cancellationToken: cancellationToken,
      onEvent: (event) => events.add(event.type),
    );

    expect(cancelledJobIds, ['job-1']);
    expect(result.project, same(project));
    expect(result.script, same(script));
    expect(result.finalJob, same(cancelledJob));
    expect(result.outcome, GeneratePodcastOutcome.cancelled);
    expect(result.audioReady, isFalse);
    expect(events, [
      GeneratePodcastEventType.projectCreated,
      GeneratePodcastEventType.scriptSaved,
      GeneratePodcastEventType.jobSubmitted,
      GeneratePodcastEventType.cancellationRequested,
      GeneratePodcastEventType.cancelled,
    ]);
  });

  test('cancels during polling before the next poll when possible', () async {
    final cancellationToken = GeneratePodcastCancellationToken();
    final cancelledJobIds = <String>[];
    final backend = FakeStudycastBackend()
      ..onCreateProject = ({required title}) async {
        return _project();
      }
      ..onSaveScript =
          ({required projectId, required text, required source}) async {
            return _script();
          }
      ..onSubmitJob = ({required projectId, options}) async {
        return _job(JobStatus.queued);
      }
      ..onGetJob = (jobId) async {
        fail('job should not be polled after cancellation is requested');
      }
      ..onCancelJob = (jobId) async {
        cancelledJobIds.add(jobId);
        return _job(JobStatus.cancelled);
      };
    final workflow = GeneratePodcastWorkflow(
      projectService: ProjectService(backend),
      scriptService: ScriptService(backend),
      jobService: JobService(backend),
      delay: (_) async {
        cancellationToken.cancel();
      },
    );

    final result = await workflow.generateFromPastedScript(
      const GeneratePodcastRequest(
        projectTitle: 'Biology 101',
        scriptText: 'Host: Hello',
      ),
      cancellationToken: cancellationToken,
    );

    expect(cancelledJobIds, ['job-1']);
    expect(result.finalJob?.status, JobStatus.cancelled);
    expect(result.outcome, GeneratePodcastOutcome.cancelled);
  });

  test('does not cancel when a refreshed job is already terminal', () async {
    final cancellationToken = GeneratePodcastCancellationToken();
    final backend = FakeStudycastBackend()
      ..onCreateProject = ({required title}) async {
        return _project();
      }
      ..onSaveScript =
          ({required projectId, required text, required source}) async {
            return _script();
          }
      ..onSubmitJob = ({required projectId, options}) async {
        return _job(JobStatus.queued);
      }
      ..onGetJob = (jobId) async {
        cancellationToken.cancel();
        return _job(JobStatus.completed, progressPercent: 100);
      }
      ..onCancelJob = (jobId) async {
        fail('terminal refreshed jobs should not be cancelled');
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
      cancellationToken: cancellationToken,
    );

    expect(result.finalJob?.status, JobStatus.completed);
    expect(result.outcome, GeneratePodcastOutcome.completed);
    expect(result.audioReady, isTrue);
  });

  test('propagates backend cancel failures', () async {
    const failure = ApiFailure(message: 'cancel failed');
    final cancellationToken = GeneratePodcastCancellationToken();
    final backend = FakeStudycastBackend()
      ..onCreateProject = ({required title}) async {
        return _project();
      }
      ..onSaveScript =
          ({required projectId, required text, required source}) async {
            return _script();
          }
      ..onSubmitJob = ({required projectId, options}) async {
        cancellationToken.cancel();
        return _job(JobStatus.running);
      }
      ..onCancelJob = (jobId) async {
        throw failure;
      };
    final workflow = GeneratePodcastWorkflow(
      projectService: ProjectService(backend),
      scriptService: ScriptService(backend),
      jobService: JobService(backend),
      delay: (_) async {},
    );

    await expectLater(
      workflow.generateFromPastedScript(
        const GeneratePodcastRequest(
          projectTitle: 'Biology 101',
          scriptText: 'Host: Hello',
        ),
        cancellationToken: cancellationToken,
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
