import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:studycast/domain/api/studycast_models.dart';
import 'package:studycast/infrastructure/http/studycast_api_client.dart';

void main() {
  test('submits a project job with voice and TTS options', () async {
    final client = StudycastApiClient(
      baseUrl: Uri.parse('http://example.test'),
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(), 'http://example.test/api/v1/projects/project-1/jobs');
        expect(jsonDecode(request.body), {
          'voice_profile_id': 'voice-1',
          'tts_params': {'temperature': 0.4},
        });
        return _jsonResponse(_jobJson(status: 'queued'), statusCode: 202);
      }),
    );

    final job = await client.submitJob(
      projectId: 'project-1',
      options: const StartJobOptions(
        voiceProfileId: 'voice-1',
        ttsParams: {'temperature': 0.4},
      ),
    );

    expect(job.status, JobStatus.queued);
    expect(job.phase, JobPhase.queued);
  });

  test('lists jobs with status, project, and search filters', () async {
    final client = StudycastApiClient(
      baseUrl: Uri.parse('http://example.test'),
      httpClient: MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.toString(),
          'http://example.test/api/v1/jobs?status=queued%2Crunning&project_id=project-1&q=bio',
        );
        return _jsonResponse([_jobJson(status: 'running')]);
      }),
    );

    final jobs = await client.listJobs(
      statuses: [JobStatus.queued, JobStatus.running],
      projectId: 'project-1',
      query: 'bio',
    );

    expect(jobs.single.status, JobStatus.running);
  });

  test('gets, cancels, reruns jobs, and fetches the job script', () async {
    final seen = <String>[];
    final client = StudycastApiClient(
      baseUrl: Uri.parse('http://example.test'),
      httpClient: MockClient((request) async {
        seen.add('${request.method} ${request.url.path}');
        if (request.url.path.endsWith('/script')) {
          return _jsonResponse(_scriptJson());
        }
        return _jsonResponse(_jobJson(status: 'cancel_requested'));
      }),
    );

    final job = await client.getJob('job-1');
    final cancelled = await client.cancelJob('job-1');
    final rerun = await client.rerunJob('job-1');
    final script = await client.getJobScript('job-1');

    expect(job.id, 'job-1');
    expect(cancelled.status, JobStatus.cancelRequested);
    expect(rerun.status, JobStatus.cancelRequested);
    expect(script.projectId, 'project-1');
    expect(seen, [
      'GET /api/v1/jobs/job-1',
      'POST /api/v1/jobs/job-1/cancel',
      'POST /api/v1/jobs/job-1/rerun',
      'GET /api/v1/jobs/job-1/script',
    ]);
  });

  test('gets queue summary', () async {
    final client = StudycastApiClient(
      baseUrl: Uri.parse('http://example.test'),
      httpClient: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), 'http://example.test/api/v1/queue');
        return _jsonResponse({
          'pending_count': 2,
          'running_count': 1,
          'completed_count': 9,
          'max_active_jobs_total': 3,
          'concurrency_limits': {'tts': 1},
          'queue_positions': {'job-2': 0},
        });
      }),
    );

    final queue = await client.getQueueSummary();

    expect(queue.pendingCount, 2);
    expect(queue.queuePositions['job-2'], 0);
  });
}

Map<String, Object?> _jobJson({required String status}) {
  return {
    'id': 'job-1',
    'project_id': 'project-1',
    'status': status,
    'phase': 'queued',
    'progress_percent': 0,
    'total_chunks': 1,
    'completed_chunks': 0,
    'current_chunk_index': null,
    'current_chunk_preview': null,
    'message': 'Queued',
    'failure_reason': null,
    'cancellation_requested': status == 'cancel_requested',
    'created_at': '2026-06-15T10:00:00Z',
    'started_at': null,
    'updated_at': '2026-06-15T10:00:00Z',
    'completed_at': null,
    'snapshot': null,
  };
}

Map<String, Object?> _scriptJson() {
  return {
    'project_id': 'project-1',
    'text': 'Host: Welcome',
    'source': 'pasted',
    'speakers': ['Host'],
    'updated_at': '2026-06-15T10:00:00Z',
    'chunks': [
      {'index': 0, 'speaker': 'Host', 'text': 'Welcome'},
    ],
  };
}

http.Response _jsonResponse(Object body, {int statusCode = 200}) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: {'content-type': 'application/json'},
  );
}
