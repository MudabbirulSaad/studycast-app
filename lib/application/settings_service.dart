import 'package:studycast/domain/api/studycast_backend.dart';
import 'package:studycast/domain/api/studycast_models.dart';

class SettingsService {
  const SettingsService(this._backend);

  final StudycastBackend _backend;

  Future<RuntimeSettings> getRuntimeSettings() {
    return _backend.getRuntimeSettings();
  }

  Future<RuntimeSettings> updateRuntimeSettings(Map<String, Object> values) {
    return _backend.updateRuntimeSettings(values);
  }

  Future<RuntimeStatus> reloadSettings() {
    return _backend.reloadSettings();
  }

  Future<RuntimeStatus> getRuntimeStatus() {
    return _backend.getRuntimeStatus();
  }

  Future<TtsEngineSettings> getTtsEngines() {
    return _backend.getTtsEngines();
  }

  Future<TtsEngineSettings> updateTtsEngine(String engine) {
    return _backend.updateTtsEngine(engine);
  }
}
