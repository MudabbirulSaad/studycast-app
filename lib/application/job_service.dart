import 'package:studycast/domain/api/studycast_backend.dart';
import 'package:studycast/domain/api/studycast_models.dart';

class JobService {
  const JobService(this._backend);

  final StudycastBackend _backend;

  Future<Job> submitJob({
    required String projectId,
    StartJobOptions? options,
  }) {
    return _backend.submitJob(projectId: projectId, options: options);
  }

  Future<List<Job>> findJobs({
    List<JobStatus> statuses = const [],
    String? projectId,
    String? query,
  }) {
    return _backend.listJobs(
      statuses: statuses,
      projectId: projectId,
      query: query,
    );
  }

  Future<Job> getJob(String jobId) {
    return _backend.getJob(jobId);
  }

  Future<Job> cancelJob(String jobId) {
    return _backend.cancelJob(jobId);
  }

  Future<Job> rerunJob(String jobId) {
    return _backend.rerunJob(jobId);
  }

  Future<Script> getJobScript(String jobId) {
    return _backend.getJobScript(jobId);
  }

  Future<QueueSummary> getQueueSummary() {
    return _backend.getQueueSummary();
  }
}
