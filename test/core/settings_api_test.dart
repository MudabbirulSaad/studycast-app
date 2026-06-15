import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:studycast/infrastructure/http/studycast_api_client.dart';

void main() {
  test('gets runtime settings', () async {
    final client = StudycastApiClient(
      baseUrl: Uri.parse('http://example.test'),
      httpClient: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), 'http://example.test/api/v1/settings');
        return _jsonResponse(_settingsJson());
      }),
    );

    final settings = await client.getRuntimeSettings();

    expect(settings.values.activeTtsEngine, 'fake');
    expect(settings.editableFields, contains('active_tts_engine'));
  });

  test('updates runtime settings with editable values payload', () async {
    final client = StudycastApiClient(
      baseUrl: Uri.parse('http://example.test'),
      httpClient: MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.toString(), 'http://example.test/api/v1/settings');
        expect(jsonDecode(request.body), {
          'values': {
            'active_tts_engine': 'fake',
            'max_chunk_chars': 320,
            'serve_frontend': false,
          },
        });
        return _jsonResponse(_settingsJson());
      }),
    );

    final settings = await client.updateRuntimeSettings({
      'active_tts_engine': 'fake',
      'max_chunk_chars': 320,
      'serve_frontend': false,
    });

    expect(settings.reloadRequired, isFalse);
  });

  test('reloads settings and gets runtime status', () async {
    final seen = <String>[];
    final client = StudycastApiClient(
      baseUrl: Uri.parse('http://example.test'),
      httpClient: MockClient((request) async {
        seen.add('${request.method} ${request.url.path}');
        return _jsonResponse(
          _runtimeStatusJson(),
          statusCode: request.method == 'POST' ? 202 : 200,
        );
      }),
    );

    final reload = await client.reloadSettings();
    final status = await client.getRuntimeStatus();

    expect(reload.status, 'ready');
    expect(status.activeEngine, 'fake');
    expect(seen, [
      'POST /api/v1/settings/reload',
      'GET /api/v1/settings/runtime-status',
    ]);
  });

  test('gets and updates TTS engine settings', () async {
    final seen = <String>[];
    final client = StudycastApiClient(
      baseUrl: Uri.parse('http://example.test'),
      httpClient: MockClient((request) async {
        seen.add('${request.method} ${request.url.path}');
        if (request.method == 'PUT') {
          expect(jsonDecode(request.body), {'engine': 'fake'});
        }
        return _jsonResponse({
          'active_engine': 'fake',
          'available_engines': ['fake', 'chatterbox'],
        });
      }),
    );

    final engines = await client.getTtsEngines();
    final updated = await client.updateTtsEngine('fake');

    expect(engines.availableEngines, contains('chatterbox'));
    expect(updated.activeEngine, 'fake');
    expect(seen, [
      'GET /api/v1/settings/tts-engines',
      'PUT /api/v1/settings/tts-engine',
    ]);
  });
}

Map<String, Object?> _settingsJson() {
  return {
    'values': {
      'active_tts_engine': 'fake',
      'chatterbox_device': 'cpu',
      'max_script_size_bytes': 100000,
      'max_chunk_chars': 320,
      'max_chunks': 20,
      'chatterbox_max_concurrent_jobs': 1,
      'audio_merge_max_concurrent_jobs': 1,
      'max_active_jobs_total': 2,
      'storage_root': '/tmp/studycast',
      'frontend_origin': 'http://localhost:3000',
      'serve_frontend': false,
    },
    'editable_fields': ['active_tts_engine', 'max_chunk_chars'],
    'available_engines': ['fake'],
    'reload_required': false,
    'runtime_status': 'ready',
    'last_reload_error': null,
  };
}

Map<String, Object?> _runtimeStatusJson() {
  return {
    'status': 'ready',
    'active_engine': 'fake',
    'reload_required': false,
    'last_reload_error': null,
  };
}

http.Response _jsonResponse(Object body, {int statusCode = 200}) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: {'content-type': 'application/json'},
  );
}
