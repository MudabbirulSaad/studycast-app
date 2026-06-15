import 'package:flutter_test/flutter_test.dart';
import 'package:studycast/application/job_service.dart';
import 'package:studycast/domain/api/api_failure.dart';
import 'package:studycast/domain/api/studycast_models.dart';

import 'fake_studycast_backend.dart';

void main() {
  test('submits, lists, controls, inspects jobs, and gets queue status', () async {
    final job = _job(JobStatus.running);
    final script = _script();
    final queue = _queue();
    final options = const StartJobOptions(
      voiceProfileId: 'voice-1',
      ttsParams: {'temperature': 0.4},
    );
    final calls = <String>[];
    final backend = FakeStudycastBackend()
      ..onSubmitJob = ({required projectId, options}) async {
        calls.add('submit:$projectId:${options?.voiceProfileId}');
        return job;
      }
      ..onListJobs = ({statuses = const [], projectId, query}) async {
        calls.add(
          'list:${statuses.map((status) => status.toJson()).join('|')}:$projectId:$query',
        );
        return [job];
      }
      ..onGetJob = (jobId) async {
        calls.add('get:$jobId');
        return job;
      }
      ..onCancelJob = (jobId) async {
        calls.add('cancel:$jobId');
        return _job(JobStatus.cancelRequested);
      }
      ..onRerunJob = (jobId) async {
        calls.add('rerun:$jobId');
        return _job(JobStatus.queued);
      }
      ..onGetJobScript = (jobId) async {
        calls.add('script:$jobId');
        return script;
      }
      ..onGetQueueSummary = () async {
        calls.add('queue');
        return queue;
      };
    final service = JobService(backend);

    expect(await service.submitJob(projectId: 'project-1', options: options), same(job));
    expect(
      await service.findJobs(
        statuses: [JobStatus.queued, JobStatus.running],
        projectId: 'project-1',
        query: 'bio',
      ),
      [same(job)],
    );
    expect(await service.getJob('job-1'), same(job));
    expect((await service.cancelJob('job-1')).status, JobStatus.cancelRequested);
    expect((await service.rerunJob('job-1')).status, JobStatus.queued);
    expect(await service.getJobScript('job-1'), same(script));
    expect(await service.getQueueSummary(), same(queue));
    expect(calls, [
      'submit:project-1:voice-1',
      'list:queued|running:project-1:bio',
      'get:job-1',
      'cancel:job-1',
      'rerun:job-1',
      'script:job-1',
      'queue',
    ]);
  });

  test('lets backend failures propagate', () async {
    const failure = ApiFailure(message: 'active job exists', code: 'active_job_exists');
    final backend = FakeStudycastBackend()
      ..onSubmitJob = ({required projectId, options}) async => throw failure;
    final service = JobService(backend);

    await expectLater(
      service.submitJob(projectId: 'project-1'),
      throwsA(same(failure)),
    );
  });
}

Job _job(JobStatus status) {
  return Job(
    id: 'job-1',
    projectId: 'project-1',
    status: status,
    phase: JobPhase.queued,
    progressPercent: 0,
    totalChunks: 1,
    completedChunks: 0,
    currentChunkIndex: null,
    currentChunkPreview: null,
    message: 'Queued',
    failureReason: null,
    cancellationRequested: status == JobStatus.cancelRequested,
    createdAt: DateTime.utc(2026, 6, 15),
    startedAt: null,
    updatedAt: DateTime.utc(2026, 6, 15),
    completedAt: null,
    snapshot: null,
  );
}

Script _script() {
  return Script(
    projectId: 'project-1',
    text: 'Host: Hello',
    source: ScriptSource.pasted,
    speakers: const ['Host'],
    updatedAt: DateTime.utc(2026, 6, 15),
    chunks: const [Chunk(index: 0, speaker: 'Host', text: 'Hello')],
  );
}

QueueSummary _queue() {
  return const QueueSummary(
    pendingCount: 1,
    runningCount: 1,
    completedCount: 2,
    maxActiveJobsTotal: 3,
    concurrencyLimits: {'tts': 1},
    queuePositions: {'job-2': 0},
  );
}
