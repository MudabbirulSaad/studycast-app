import 'package:studycast/domain/api/studycast_models.dart';

abstract interface class StudycastBackend {
  Future<ProjectSummary> createProject({required String title});

  Future<List<ProjectSummary>> listProjects({String? query});

  Future<ProjectDetail> getProject(String projectId);

  Future<Script> saveScript({
    required String projectId,
    required String text,
    ScriptSource source,
  });

  Future<Script> uploadScriptFile({
    required String projectId,
    required String filename,
    required List<int> bytes,
  });

  Future<Script> getScript(String projectId);

  Future<Job> submitJob({required String projectId, StartJobOptions? options});

  Future<List<Job>> listJobs({
    List<JobStatus> statuses,
    String? projectId,
    String? query,
  });

  Future<Job> getJob(String jobId);

  Future<Job> cancelJob(String jobId);

  Future<Job> rerunJob(String jobId);

  Future<Script> getJobScript(String jobId);

  Future<QueueSummary> getQueueSummary();

  Future<AudioBytes> downloadProjectFinalAudio(
    String projectId, {
    String? range,
  });

  Future<AudioBytes> streamProjectFinalAudio(String projectId, {String? range});

  Future<AudioBytes> downloadJobFinalAudio(String jobId, {String? range});

  Future<AudioBytes> streamJobAudio(String jobId, {String? range});

  Future<RuntimeSettings> getRuntimeSettings();

  Future<RuntimeSettings> updateRuntimeSettings(Map<String, Object> values);

  Future<RuntimeStatus> reloadSettings();

  Future<RuntimeStatus> getRuntimeStatus();

  Future<TtsEngineSettings> getTtsEngines();

  Future<TtsEngineSettings> updateTtsEngine(String engine);

  Future<List<VoiceProfile>> listVoices();

  Future<VoiceProfile> uploadVoice({
    required String displayName,
    required String filename,
    required List<int> bytes,
  });
}
