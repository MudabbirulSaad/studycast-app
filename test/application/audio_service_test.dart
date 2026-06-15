import 'package:flutter_test/flutter_test.dart';
import 'package:studycast/application/audio_service.dart';
import 'package:studycast/domain/api/api_failure.dart';
import 'package:studycast/domain/api/studycast_models.dart';

import 'fake_studycast_backend.dart';

void main() {
  test(
    'downloads and streams project and job audio through the backend port',
    () async {
      const audio = AudioBytes(
        bytes: [82, 73, 70, 70],
        statusCode: 206,
        headers: {'content-range': 'bytes 0-3/10'},
      );
      final calls = <String>[];
      final backend = FakeStudycastBackend()
        ..onDownloadProjectFinalAudio = (projectId, {range}) async {
          calls.add('project-final:$projectId:$range');
          return audio;
        }
        ..onStreamProjectFinalAudio = (projectId, {range}) async {
          calls.add('project-stream:$projectId:$range');
          return audio;
        }
        ..onDownloadJobFinalAudio = (jobId, {range}) async {
          calls.add('job-final:$jobId:$range');
          return audio;
        }
        ..onStreamJobAudio = (jobId, {range}) async {
          calls.add('job-stream:$jobId:$range');
          return audio;
        };
      final service = AudioService(backend);

      expect(await service.downloadProjectFinal('project-1'), same(audio));
      expect(
        await service.streamProjectFinal('project-1', range: 'bytes=0-3'),
        same(audio),
      );
      expect(await service.downloadJobFinal('job-1'), same(audio));
      expect(await service.streamJob('job-1', range: 'bytes=0-3'), same(audio));
      expect(calls, [
        'project-final:project-1:null',
        'project-stream:project-1:bytes=0-3',
        'job-final:job-1:null',
        'job-stream:job-1:bytes=0-3',
      ]);
    },
  );

  test('lets backend failures propagate', () async {
    const failure = ApiFailure(message: 'missing final WAV', code: 'not_found');
    final backend = FakeStudycastBackend()
      ..onDownloadProjectFinalAudio = (projectId, {range}) async =>
          throw failure;
    final service = AudioService(backend);

    await expectLater(
      service.downloadProjectFinal('project-1'),
      throwsA(same(failure)),
    );
  });
}
