import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:studycast/domain/api/api_failure.dart';
import 'package:studycast/infrastructure/http/studycast_api_client.dart';

void main() {
  test('downloads project final audio bytes', () async {
    final client = StudycastApiClient(
      baseUrl: Uri.parse('http://example.test'),
      httpClient: MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.toString(),
          'http://example.test/api/v1/projects/project-1/audio/final',
        );
        return http.Response.bytes(
          [82, 73, 70, 70],
          200,
          headers: {
            'content-type': 'audio/wav',
            'accept-ranges': 'bytes',
            'content-length': '4',
          },
        );
      }),
    );

    final audio = await client.downloadProjectFinalAudio('project-1');

    expect(audio.bytes, [82, 73, 70, 70]);
    expect(audio.headers['accept-ranges'], 'bytes');
  });

  test('streams job audio with a byte range header', () async {
    final client = StudycastApiClient(
      baseUrl: Uri.parse('http://example.test'),
      httpClient: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.headers['range'], 'bytes=0-1023');
        expect(
          request.url.toString(),
          'http://example.test/api/v1/jobs/job-1/audio/stream',
        );
        return http.Response.bytes(
          [1, 2, 3],
          206,
          headers: {
            'content-type': 'audio/wav',
            'content-range': 'bytes 0-2/10',
          },
        );
      }),
    );

    final audio = await client.streamJobAudio('job-1', range: 'bytes=0-1023');

    expect(audio.statusCode, 206);
    expect(audio.headers['content-range'], 'bytes 0-2/10');
  });

  test('maps plain text audio range errors', () async {
    final client = StudycastApiClient(
      baseUrl: Uri.parse('http://example.test'),
      httpClient: MockClient((_) async {
        return http.Response(
          'Malformed Range header',
          400,
          headers: {'content-type': 'text/plain'},
        );
      }),
    );

    await expectLater(
      client.streamProjectFinalAudio('project-1', range: 'nope'),
      throwsA(
        isA<ApiFailure>()
            .having((failure) => failure.statusCode, 'statusCode', 400)
            .having((failure) => failure.message, 'message', 'Malformed Range header'),
      ),
    );
  });
}
