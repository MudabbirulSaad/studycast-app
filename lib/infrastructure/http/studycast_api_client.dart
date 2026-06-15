import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:studycast/domain/api/api_failure.dart';
import 'package:studycast/domain/api/studycast_models.dart';

class StudycastApiClient {
  StudycastApiClient({
    required Uri baseUrl,
    http.Client? httpClient,
  })  : _baseUrl = _normalizeBaseUrl(baseUrl),
        _httpClient = httpClient ?? http.Client();

  final Uri _baseUrl;
  final http.Client _httpClient;

  Future<ProjectSummary> createProject({required String title}) async {
    final response = await _sendJson(
      'POST',
      ['projects'],
      body: {'title': title},
    );
    return ProjectSummary.fromJson(_jsonObject(response));
  }

  Future<List<ProjectSummary>> listProjects({String? query}) async {
    final response = await _sendJson(
      'GET',
      ['projects'],
      queryParameters: _optionalQuery({'q': query}),
    );
    return _jsonList(response, ProjectSummary.fromJson);
  }

  Future<ProjectDetail> getProject(String projectId) async {
    final response = await _sendJson('GET', ['projects', projectId]);
    return ProjectDetail.fromJson(_jsonObject(response));
  }

  Future<Script> saveScript({
    required String projectId,
    required String text,
    ScriptSource source = ScriptSource.pasted,
  }) async {
    final response = await _sendJson(
      'PUT',
      ['projects', projectId, 'script'],
      body: {'text': text, 'source': source.toJson()},
    );
    return Script.fromJson(_jsonObject(response));
  }

  Future<Script> uploadScriptFile({
    required String projectId,
    required String filename,
    required List<int> bytes,
  }) async {
    final request = http.MultipartRequest(
      'PUT',
      _uri(['projects', projectId, 'script']),
    );
    request.headers['accept'] = 'application/json';
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType('text', 'plain'),
      ),
    );
    final response = _checkedResponse(
      await http.Response.fromStream(await _httpClient.send(request)),
    );
    return Script.fromJson(_jsonObject(response));
  }

  Future<Script> getScript(String projectId) async {
    final response = await _sendJson('GET', ['projects', projectId, 'script']);
    return Script.fromJson(_jsonObject(response));
  }

  Future<http.Response> _sendJson(
    String method,
    List<String> pathSegments, {
    Map<String, String>? queryParameters,
    Map<String, Object?>? body,
    Map<String, String>? headers,
  }) async {
    final request = http.Request(method, _uri(pathSegments, queryParameters));
    request.headers.addAll({
      'accept': 'application/json',
      if (body != null) 'content-type': 'application/json',
      ...?headers,
    });
    if (body != null) {
      request.body = jsonEncode(body);
    }
    return _checkedResponse(await http.Response.fromStream(await _httpClient.send(request)));
  }

  http.Response _checkedResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }
    throw _failureFromResponse(response);
  }

  ApiFailure _failureFromResponse(http.Response response) {
    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      return ApiFailure(
        statusCode: response.statusCode,
        message: response.body.isEmpty ? 'HTTP ${response.statusCode}' : response.body,
      );
    }

    try {
      final body = jsonDecode(response.body) as Map<String, Object?>;
      final validationDetails = body['detail'];
      if (validationDetails is List<Object?>) {
        return ApiFailure(
          statusCode: response.statusCode,
          code: 'validation_error',
          message: 'Request validation failed.',
          validationErrors: validationDetails
              .map((item) => ValidationIssue.fromJson(item as Map<String, Object?>))
              .toList(growable: false),
        );
      }
      return ApiFailure(
        statusCode: response.statusCode,
        code: body['code'] as String?,
        message: body['message'] as String? ?? 'HTTP ${response.statusCode}',
        details: body['details'],
      );
    } on FormatException catch (error) {
      return ApiFailure(
        statusCode: response.statusCode,
        message: 'Failed to parse error response.',
        cause: error,
      );
    }
  }

  Map<String, Object?> _jsonObject(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, Object?>;
    } on Object catch (error) {
      throw ApiFailure(message: 'Failed to parse API response.', cause: error);
    }
  }

  List<T> _jsonList<T>(
    http.Response response,
    T Function(Map<String, Object?> json) parse,
  ) {
    try {
      return (jsonDecode(response.body) as List<Object?>)
          .map((item) => parse(item as Map<String, Object?>))
          .toList(growable: false);
    } on Object catch (error) {
      throw ApiFailure(message: 'Failed to parse API response.', cause: error);
    }
  }

  Uri _uri(List<String> pathSegments, [Map<String, String>? queryParameters]) {
    final baseSegments = _baseUrl.pathSegments.where((segment) => segment.isNotEmpty);
    return _baseUrl.replace(
      pathSegments: [...baseSegments, 'api', 'v1', ...pathSegments],
      queryParameters: queryParameters?.isEmpty ?? true ? null : queryParameters,
    );
  }

  static Uri _normalizeBaseUrl(Uri uri) {
    final text = uri.toString();
    if (text.length > uri.origin.length && text.endsWith('/')) {
      return Uri.parse(text.substring(0, text.length - 1));
    }
    return uri;
  }
}

Map<String, String> _optionalQuery(Map<String, String?> values) {
  return {
    for (final entry in values.entries)
      if (entry.value != null && entry.value!.isNotEmpty) entry.key: entry.value!,
  };
}

http.MultipartFile bytesMultipartFile({
  required String field,
  required String filename,
  required List<int> bytes,
  MediaType? contentType,
}) {
  return http.MultipartFile.fromBytes(
    field,
    bytes,
    filename: filename,
    contentType: contentType,
  );
}
