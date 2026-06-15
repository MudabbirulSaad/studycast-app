import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:studycast/domain/api/studycast_models.dart';
import 'package:studycast/infrastructure/http/studycast_api_client.dart';

void main() {
  test('saves a pasted script as JSON', () async {
    final client = StudycastApiClient(
      baseUrl: Uri.parse('http://example.test'),
      httpClient: _CapturingClient((request) async {
        expect(request, isA<http.Request>());
        final jsonRequest = request as http.Request;
        expect(jsonRequest.method, 'PUT');
        expect(
          jsonRequest.url.toString(),
          'http://example.test/api/v1/projects/project-1/script',
        );
        expect(jsonDecode(jsonRequest.body), {
          'text': 'Host: Welcome',
          'source': 'pasted',
        });
        return _jsonResponse(_scriptJson(source: 'pasted'));
      }),
    );

    final script = await client.saveScript(
      projectId: 'project-1',
      text: 'Host: Welcome',
    );

    expect(script.source, ScriptSource.pasted);
    expect(script.chunks.single.text, 'Welcome');
  });

  test('uploads a script text file as multipart form data', () async {
    final client = StudycastApiClient(
      baseUrl: Uri.parse('http://example.test'),
      httpClient: _CapturingClient((request) async {
        expect(request, isA<http.MultipartRequest>());
        final multipart = request as http.MultipartRequest;
        expect(multipart.method, 'PUT');
        expect(
          multipart.url.toString(),
          'http://example.test/api/v1/projects/project-1/script',
        );
        expect(multipart.files.single.field, 'file');
        expect(multipart.files.single.filename, 'lesson.txt');
        expect(multipart.files.single.contentType.toString(), 'text/plain');
        return _jsonResponse(_scriptJson(source: 'uploaded'));
      }),
    );

    final script = await client.uploadScriptFile(
      projectId: 'project-1',
      filename: 'lesson.txt',
      bytes: utf8.encode('Host: Welcome'),
    );

    expect(script.source, ScriptSource.uploaded);
  });

  test('gets the active script for a project', () async {
    final client = StudycastApiClient(
      baseUrl: Uri.parse('http://example.test'),
      httpClient: _CapturingClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.toString(),
          'http://example.test/api/v1/projects/project-1/script',
        );
        return _jsonResponse(_scriptJson(source: 'pasted'));
      }),
    );

    final script = await client.getScript('project-1');

    expect(script.projectId, 'project-1');
    expect(script.speakers, ['Host']);
  });
}

Map<String, Object?> _scriptJson({required String source}) {
  return {
    'project_id': 'project-1',
    'text': 'Host: Welcome',
    'source': source,
    'speakers': ['Host'],
    'updated_at': '2026-06-15T10:00:00Z',
    'chunks': [
      {'index': 0, 'speaker': 'Host', 'text': 'Welcome'},
    ],
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
