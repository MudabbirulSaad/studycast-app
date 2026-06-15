import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:studycast/domain/api/api_failure.dart';
import 'package:studycast/infrastructure/http/studycast_api_client.dart';

void main() {
  test('creates a project with a typed response', () async {
    final requests = <http.Request>[];
    final client = StudycastApiClient(
      baseUrl: Uri.parse('http://example.test/root/'),
      httpClient: MockClient((request) async {
        requests.add(request);
        expect(request.method, 'POST');
        expect(request.url.toString(), 'http://example.test/root/api/v1/projects');
        expect(jsonDecode(request.body), {'title': 'Biology 101'});
        return http.Response(
          jsonEncode({
            'id': '018f41d2-06f2-7d08-923b-43b8ec39bf2d',
            'title': 'Biology 101',
            'created_at': '2026-06-15T10:00:00Z',
            'updated_at': '2026-06-15T10:00:00Z',
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final project = await client.createProject(title: 'Biology 101');

    expect(project.id, '018f41d2-06f2-7d08-923b-43b8ec39bf2d');
    expect(project.title, 'Biology 101');
    expect(requests, hasLength(1));
  });

  test('lists projects with an optional search query', () async {
    final client = StudycastApiClient(
      baseUrl: Uri.parse('http://example.test'),
      httpClient: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), 'http://example.test/api/v1/projects?q=bio');
        return http.Response(
          jsonEncode([
            {
              'id': 'project-1',
              'title': 'Biology 101',
              'created_at': '2026-06-15T10:00:00Z',
              'updated_at': '2026-06-15T10:00:00Z',
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final projects = await client.listProjects(query: 'bio');

    expect(projects.single.title, 'Biology 101');
  });

  test('gets a project detail including latest jobs', () async {
    final client = StudycastApiClient(
      baseUrl: Uri.parse('http://example.test'),
      httpClient: MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.toString(),
          'http://example.test/api/v1/projects/project-1',
        );
        return http.Response(
          jsonEncode({
            'id': 'project-1',
            'title': 'Biology 101',
            'created_at': '2026-06-15T10:00:00Z',
            'updated_at': '2026-06-15T10:00:00Z',
            'has_active_script': true,
            'latest_jobs': [],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final detail = await client.getProject('project-1');

    expect(detail.hasActiveScript, isTrue);
    expect(detail.latestJobs, isEmpty);
  });

  test('maps API error responses into ApiFailure', () async {
    final client = StudycastApiClient(
      baseUrl: Uri.parse('http://example.test'),
      httpClient: MockClient((_) async {
        return http.Response(
          jsonEncode({
            'code': 'domain_error',
            'message': 'empty project title',
            'details': {'field': 'title'},
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    await expectLater(
      client.createProject(title: ''),
      throwsA(
        isA<ApiFailure>()
            .having((failure) => failure.statusCode, 'statusCode', 400)
            .having((failure) => failure.code, 'code', 'domain_error')
            .having((failure) => failure.message, 'message', 'empty project title'),
      ),
    );
  });
}
