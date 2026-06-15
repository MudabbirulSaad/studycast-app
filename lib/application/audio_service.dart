import 'package:studycast/domain/api/studycast_backend.dart';
import 'package:studycast/domain/api/studycast_models.dart';

class AudioService {
  const AudioService(this._backend);

  final StudycastBackend _backend;

  Future<AudioBytes> downloadProjectFinal(String projectId, {String? range}) {
    return _backend.downloadProjectFinalAudio(projectId, range: range);
  }

  Future<AudioBytes> streamProjectFinal(String projectId, {String? range}) {
    return _backend.streamProjectFinalAudio(projectId, range: range);
  }

  Future<AudioBytes> downloadJobFinal(String jobId, {String? range}) {
    return _backend.downloadJobFinalAudio(jobId, range: range);
  }

  Future<AudioBytes> streamJob(String jobId, {String? range}) {
    return _backend.streamJobAudio(jobId, range: range);
  }
}
