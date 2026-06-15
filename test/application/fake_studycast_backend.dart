import 'package:studycast/domain/api/studycast_backend.dart';
import 'package:studycast/domain/api/studycast_models.dart';

class FakeStudycastBackend implements StudycastBackend {
  Future<ProjectSummary> Function({required String title})? onCreateProject;
  Future<List<ProjectSummary>> Function({String? query})? onListProjects;
  Future<ProjectDetail> Function(String projectId)? onGetProject;
  Future<Script> Function({
    required String projectId,
    required String text,
    required ScriptSource source,
  })?
  onSaveScript;
  Future<Script> Function({
    required String projectId,
    required String filename,
    required List<int> bytes,
  })?
  onUploadScriptFile;
  Future<Script> Function(String projectId)? onGetScript;
  Future<Job> Function({required String projectId, StartJobOptions? options})?
  onSubmitJob;
  Future<List<Job>> Function({
    List<JobStatus> statuses,
    String? projectId,
    String? query,
  })?
  onListJobs;
  Future<Job> Function(String jobId)? onGetJob;
  Future<Job> Function(String jobId)? onCancelJob;
  Future<Job> Function(String jobId)? onRerunJob;
  Future<Script> Function(String jobId)? onGetJobScript;
  Future<QueueSummary> Function()? onGetQueueSummary;
  Future<AudioBytes> Function(String projectId, {String? range})?
  onDownloadProjectFinalAudio;
  Future<AudioBytes> Function(String projectId, {String? range})?
  onStreamProjectFinalAudio;
  Future<AudioBytes> Function(String jobId, {String? range})?
  onDownloadJobFinalAudio;
  Future<AudioBytes> Function(String jobId, {String? range})? onStreamJobAudio;
  Future<RuntimeSettings> Function()? onGetRuntimeSettings;
  Future<RuntimeSettings> Function(Map<String, Object> values)?
  onUpdateRuntimeSettings;
  Future<RuntimeStatus> Function()? onReloadSettings;
  Future<RuntimeStatus> Function()? onGetRuntimeStatus;
  Future<TtsEngineSettings> Function()? onGetTtsEngines;
  Future<TtsEngineSettings> Function(String engine)? onUpdateTtsEngine;
  Future<List<VoiceProfile>> Function()? onListVoices;
  Future<VoiceProfile> Function({
    required String displayName,
    required String filename,
    required List<int> bytes,
  })?
  onUploadVoice;

  @override
  Future<ProjectSummary> createProject({required String title}) {
    return onCreateProject?.call(title: title) ?? _missing('createProject');
  }

  @override
  Future<List<ProjectSummary>> listProjects({String? query}) {
    return onListProjects?.call(query: query) ?? _missing('listProjects');
  }

  @override
  Future<ProjectDetail> getProject(String projectId) {
    return onGetProject?.call(projectId) ?? _missing('getProject');
  }

  @override
  Future<Script> saveScript({
    required String projectId,
    required String text,
    ScriptSource source = ScriptSource.pasted,
  }) {
    return onSaveScript?.call(
          projectId: projectId,
          text: text,
          source: source,
        ) ??
        _missing('saveScript');
  }

  @override
  Future<Script> uploadScriptFile({
    required String projectId,
    required String filename,
    required List<int> bytes,
  }) {
    return onUploadScriptFile?.call(
          projectId: projectId,
          filename: filename,
          bytes: bytes,
        ) ??
        _missing('uploadScriptFile');
  }

  @override
  Future<Script> getScript(String projectId) {
    return onGetScript?.call(projectId) ?? _missing('getScript');
  }

  @override
  Future<Job> submitJob({required String projectId, StartJobOptions? options}) {
    return onSubmitJob?.call(projectId: projectId, options: options) ??
        _missing('submitJob');
  }

  @override
  Future<List<Job>> listJobs({
    List<JobStatus> statuses = const [],
    String? projectId,
    String? query,
  }) {
    return onListJobs?.call(
          statuses: statuses,
          projectId: projectId,
          query: query,
        ) ??
        _missing('listJobs');
  }

  @override
  Future<Job> getJob(String jobId) {
    return onGetJob?.call(jobId) ?? _missing('getJob');
  }

  @override
  Future<Job> cancelJob(String jobId) {
    return onCancelJob?.call(jobId) ?? _missing('cancelJob');
  }

  @override
  Future<Job> rerunJob(String jobId) {
    return onRerunJob?.call(jobId) ?? _missing('rerunJob');
  }

  @override
  Future<Script> getJobScript(String jobId) {
    return onGetJobScript?.call(jobId) ?? _missing('getJobScript');
  }

  @override
  Future<QueueSummary> getQueueSummary() {
    return onGetQueueSummary?.call() ?? _missing('getQueueSummary');
  }

  @override
  Future<AudioBytes> downloadProjectFinalAudio(
    String projectId, {
    String? range,
  }) {
    return onDownloadProjectFinalAudio?.call(projectId, range: range) ??
        _missing('downloadProjectFinalAudio');
  }

  @override
  Future<AudioBytes> streamProjectFinalAudio(
    String projectId, {
    String? range,
  }) {
    return onStreamProjectFinalAudio?.call(projectId, range: range) ??
        _missing('streamProjectFinalAudio');
  }

  @override
  Future<AudioBytes> downloadJobFinalAudio(String jobId, {String? range}) {
    return onDownloadJobFinalAudio?.call(jobId, range: range) ??
        _missing('downloadJobFinalAudio');
  }

  @override
  Future<AudioBytes> streamJobAudio(String jobId, {String? range}) {
    return onStreamJobAudio?.call(jobId, range: range) ??
        _missing('streamJobAudio');
  }

  @override
  Future<RuntimeSettings> getRuntimeSettings() {
    return onGetRuntimeSettings?.call() ?? _missing('getRuntimeSettings');
  }

  @override
  Future<RuntimeSettings> updateRuntimeSettings(Map<String, Object> values) {
    return onUpdateRuntimeSettings?.call(values) ??
        _missing('updateRuntimeSettings');
  }

  @override
  Future<RuntimeStatus> reloadSettings() {
    return onReloadSettings?.call() ?? _missing('reloadSettings');
  }

  @override
  Future<RuntimeStatus> getRuntimeStatus() {
    return onGetRuntimeStatus?.call() ?? _missing('getRuntimeStatus');
  }

  @override
  Future<TtsEngineSettings> getTtsEngines() {
    return onGetTtsEngines?.call() ?? _missing('getTtsEngines');
  }

  @override
  Future<TtsEngineSettings> updateTtsEngine(String engine) {
    return onUpdateTtsEngine?.call(engine) ?? _missing('updateTtsEngine');
  }

  @override
  Future<List<VoiceProfile>> listVoices() {
    return onListVoices?.call() ?? _missing('listVoices');
  }

  @override
  Future<VoiceProfile> uploadVoice({
    required String displayName,
    required String filename,
    required List<int> bytes,
  }) {
    return onUploadVoice?.call(
          displayName: displayName,
          filename: filename,
          bytes: bytes,
        ) ??
        _missing('uploadVoice');
  }

  Future<T> _missing<T>(String method) {
    throw StateError('No fake handler registered for $method.');
  }
}
