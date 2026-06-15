import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:studycast/infrastructure/http/studycast_api_client.dart';

void main() {
  test('lists voice profiles', () async {
    final client = StudycastApiClient(
      baseUrl: Uri.parse('http://example.test'),
      httpClient: _CapturingClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), 'http://example.test/api/v1/voices');
        return _jsonResponse([_voiceJson()]);
      }),
    );

    final voices = await client.listVoices();

    expect(voices.single.id, 'default');
    expect(voices.single.hasSample, isFalse);
  });

  test('uploads a voice sample as multipart form data', () async {
    final client = StudycastApiClient(
      baseUrl: Uri.parse('http://example.test'),
      httpClient: _CapturingClient((request) async {
        expect(request, isA<http.MultipartRequest>());
        final multipart = request as http.MultipartRequest;
        expect(multipart.method, 'POST');
        expect(multipart.url.toString(), 'http://example.test/api/v1/voices');
        expect(multipart.fields['display_name'], 'Teacher Voice');
        expect(multipart.files.single.field, 'file');
        expect(multipart.files.single.filename, 'teacher.wav');
        return _jsonResponse(_voiceJson(id: 'voice-1', hasSample: true), statusCode: 201);
      }),
    );

    final voice = await client.uploadVoice(
      displayName: 'Teacher Voice',
      filename: 'teacher.wav',
      bytes: [1, 2, 3],
    );

    expect(voice.id, 'voice-1');
    expect(voice.hasSample, isTrue);
  });
}

Map<String, Object?> _voiceJson({String id = 'default', bool hasSample = false}) {
  return {
    'id': id,
    'display_name': id == 'default' ? 'Default' : 'Teacher Voice',
    'source': id == 'default' ? 'builtin' : 'uploaded',
    'sample_path': null,
    'has_sample': hasSample,
    'created_at': '2026-06-15T10:00:00Z',
    'updated_at': '2026-06-15T10:00:00Z',
  };
}

http.StreamedResponse _jsonResponse(Object body, {int statusCode = 200}) {
  return http.StreamedResponse(
    Stream.value(utf8.encode(jsonEncode(body))),
    statusCode,
    headers: {'content-type': 'application/json'},
  );
}

class _CapturingClient extends http.BaseClient {
  _CapturingClient(this._handler);

  final Future<http.StreamedResponse> Function(http.BaseRequest request) _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _handler(request);
  }
}
