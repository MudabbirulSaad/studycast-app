import 'package:flutter_test/flutter_test.dart';
import 'package:studycast/application/project_service.dart';
import 'package:studycast/domain/api/api_failure.dart';
import 'package:studycast/domain/api/studycast_models.dart';

import 'fake_studycast_backend.dart';

void main() {
  test('creates, searches, and loads project details through the backend port', () async {
    final project = _project();
    final detail = _projectDetail();
    final calls = <String>[];
    final backend = FakeStudycastBackend()
      ..onCreateProject = ({required title}) async {
        calls.add('create:$title');
        return project;
      }
      ..onListProjects = ({query}) async {
        calls.add('list:$query');
        return [project];
      }
      ..onGetProject = (projectId) async {
        calls.add('get:$projectId');
        return detail;
      };
    final service = ProjectService(backend);

    expect(await service.createProject('Biology 101'), same(project));
    expect(await service.searchProjects('bio'), [same(project)]);
    expect(await service.getProjectDetails('project-1'), same(detail));
    expect(calls, ['create:Biology 101', 'list:bio', 'get:project-1']);
  });

  test('lets backend failures propagate', () async {
    const failure = ApiFailure(message: 'empty project title', code: 'domain_error');
    final backend = FakeStudycastBackend()
      ..onCreateProject = ({required title}) async => throw failure;
    final service = ProjectService(backend);

    await expectLater(service.createProject(''), throwsA(same(failure)));
  });
}

ProjectSummary _project() {
  return ProjectSummary(
    id: 'project-1',
    title: 'Biology 101',
    createdAt: DateTime.utc(2026, 6, 15),
    updatedAt: DateTime.utc(2026, 6, 15),
  );
}

ProjectDetail _projectDetail() {
  return ProjectDetail(
    id: 'project-1',
    title: 'Biology 101',
    createdAt: DateTime.utc(2026, 6, 15),
    updatedAt: DateTime.utc(2026, 6, 15),
    hasActiveScript: true,
    latestJobs: const [],
  );
}
