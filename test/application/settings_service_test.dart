import 'package:flutter_test/flutter_test.dart';
import 'package:studycast/application/settings_service.dart';
import 'package:studycast/domain/api/api_failure.dart';
import 'package:studycast/domain/api/studycast_models.dart';

import 'fake_studycast_backend.dart';

void main() {
  test(
    'manages runtime settings and TTS engine settings through the backend port',
    () async {
      final settings = _settings();
      final status = _status();
      final engines = _engines();
      final calls = <String>[];
      final backend = FakeStudycastBackend()
        ..onGetRuntimeSettings = () async {
          calls.add('get-settings');
          return settings;
        }
        ..onUpdateRuntimeSettings = (values) async {
          calls.add('update-settings:${values['max_chunk_chars']}');
          return settings;
        }
        ..onReloadSettings = () async {
          calls.add('reload');
          return status;
        }
        ..onGetRuntimeStatus = () async {
          calls.add('status');
          return status;
        }
        ..onGetTtsEngines = () async {
          calls.add('engines');
          return engines;
        }
        ..onUpdateTtsEngine = (engine) async {
          calls.add('update-engine:$engine');
          return engines;
        };
      final service = SettingsService(backend);

      expect(await service.getRuntimeSettings(), same(settings));
      expect(
        await service.updateRuntimeSettings({'max_chunk_chars': 320}),
        same(settings),
      );
      expect(await service.reloadSettings(), same(status));
      expect(await service.getRuntimeStatus(), same(status));
      expect(await service.getTtsEngines(), same(engines));
      expect(await service.updateTtsEngine('fake'), same(engines));
      expect(calls, [
        'get-settings',
        'update-settings:320',
        'reload',
        'status',
        'engines',
        'update-engine:fake',
      ]);
    },
  );

  test('lets backend failures propagate', () async {
    const failure = ApiFailure(message: 'active jobs block reload');
    final backend = FakeStudycastBackend()
      ..onReloadSettings = () async => throw failure;
    final service = SettingsService(backend);

    await expectLater(service.reloadSettings(), throwsA(same(failure)));
  });
}

RuntimeSettings _settings() {
  return RuntimeSettings(
    values: const RuntimeSettingsValues(
      activeTtsEngine: 'fake',
      chatterboxDevice: 'cpu',
      maxScriptSizeBytes: 100000,
      maxChunkChars: 320,
      maxChunks: 20,
      chatterboxMaxConcurrentJobs: 1,
      audioMergeMaxConcurrentJobs: 1,
      maxActiveJobsTotal: 2,
      storageRoot: '/tmp/studycast',
      frontendOrigin: 'http://localhost:3000',
      serveFrontend: false,
    ),
    editableFields: const ['max_chunk_chars'],
    availableEngines: const ['fake'],
    reloadRequired: false,
    runtimeStatus: 'ready',
    lastReloadError: null,
  );
}

RuntimeStatus _status() {
  return const RuntimeStatus(
    status: 'ready',
    activeEngine: 'fake',
    reloadRequired: false,
    lastReloadError: null,
  );
}

TtsEngineSettings _engines() {
  return const TtsEngineSettings(
    activeEngine: 'fake',
    availableEngines: ['fake', 'chatterbox'],
  );
}
