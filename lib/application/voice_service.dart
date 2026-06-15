import 'package:studycast/domain/api/studycast_backend.dart';
import 'package:studycast/domain/api/studycast_models.dart';

class VoiceService {
  const VoiceService(this._backend);

  final StudycastBackend _backend;

  Future<List<VoiceProfile>> listVoices() {
    return _backend.listVoices();
  }

  Future<VoiceProfile> uploadVoice({
    required String displayName,
    required String filename,
    required List<int> bytes,
  }) {
    return _backend.uploadVoice(
      displayName: displayName,
      filename: filename,
      bytes: bytes,
    );
  }
}
