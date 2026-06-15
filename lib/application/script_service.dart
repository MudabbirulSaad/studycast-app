import 'package:studycast/domain/api/studycast_backend.dart';
import 'package:studycast/domain/api/studycast_models.dart';

class ScriptService {
  const ScriptService(this._backend);

  final StudycastBackend _backend;

  Future<Script> savePastedScript({
    required String projectId,
    required String text,
  }) {
    return _backend.saveScript(
      projectId: projectId,
      text: text,
      source: ScriptSource.pasted,
    );
  }

  Future<Script> uploadTextScript({
    required String projectId,
    required String filename,
    required List<int> bytes,
  }) {
    return _backend.uploadScriptFile(
      projectId: projectId,
      filename: filename,
      bytes: bytes,
    );
  }

  Future<Script> getActiveScript(String projectId) {
    return _backend.getScript(projectId);
  }
}
