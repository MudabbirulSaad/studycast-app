import 'package:studycast/domain/api/studycast_backend.dart';
import 'package:studycast/domain/api/studycast_models.dart';

class ProjectService {
  const ProjectService(this._backend);

  final StudycastBackend _backend;

  Future<ProjectSummary> createProject(String title) {
    return _backend.createProject(title: title);
  }

  Future<List<ProjectSummary>> searchProjects(String query) {
    return _backend.listProjects(query: query);
  }

  Future<List<ProjectSummary>> listProjects() {
    return _backend.listProjects();
  }

  Future<ProjectDetail> getProjectDetails(String projectId) {
    return _backend.getProject(projectId);
  }
}
