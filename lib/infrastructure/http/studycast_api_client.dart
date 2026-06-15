import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:studycast/domain/api/api_failure.dart';
import 'package:studycast/domain/api/studycast_backend.dart';
import 'package:studycast/domain/api/studycast_models.dart';

class StudycastApiClient implements StudycastBackend {
  StudycastApiClient({required Uri baseUrl, http.Client? httpClient})
    : _baseUrl = _normalizeBaseUrl(baseUrl),
      _httpClient = httpClient ?? http.Client();

  final Uri _baseUrl;
  final http.Client _httpClient;

  @override
  Future<ProjectSummary> createProject({required String title}) async {
    final response = await _sendJson(
      'POST',
      ['projects'],
      body: {'title': title},
    );
    return ProjectSummary.fromJson(_jsonObject(response));
  }

  @override
  Future<List<ProjectSummary>> listProjects({String? query}) async {
    final response = await _sendJson('GET', [
      'projects',
    ], queryParameters: _optionalQuery({'q': query}));
    return _jsonList(response, ProjectSummary.fromJson);
  }

  @override
  Future<ProjectDetail> getProject(String projectId) async {
    final response = await _sendJson('GET', ['projects', projectId]);
    return ProjectDetail.fromJson(_jsonObject(response));
  }

  @override
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

  @override
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

  @override
  Future<Script> getScript(String projectId) async {
    final response = await _sendJson('GET', ['projects', projectId, 'script']);
    return Script.fromJson(_jsonObject(response));
  }

  @override
  Future<Job> submitJob({
    required String projectId,
    StartJobOptions? options,
  }) async {
    final response = await _sendJson('POST', [
      'projects',
      projectId,
      'jobs',
    ], body: options?.toJson());
    return Job.fromJson(_jsonObject(response));
  }

  @override
  Future<List<Job>> listJobs({
    List<JobStatus> statuses = const [],
    String? projectId,
    String? query,
  }) async {
    final response = await _sendJson(
      'GET',
      ['jobs'],
      queryParameters: _optionalQuery({
        'status': statuses.map((status) => status.toJson()).join(','),
        'project_id': projectId,
        'q': query,
      }),
    );
    return _jsonList(response, Job.fromJson);
  }

  @override
  Future<Job> getJob(String jobId) async {
    final response = await _sendJson('GET', ['jobs', jobId]);
    return Job.fromJson(_jsonObject(response));
  }

  @override
  Future<Job> cancelJob(String jobId) async {
    final response = await _sendJson('POST', ['jobs', jobId, 'cancel']);
    return Job.fromJson(_jsonObject(response));
  }

  @override
  Future<Job> rerunJob(String jobId) async {
    final response = await _sendJson('POST', ['jobs', jobId, 'rerun']);
    return Job.fromJson(_jsonObject(response));
  }

  @override
  Future<Script> getJobScript(String jobId) async {
    final response = await _sendJson('GET', ['jobs', jobId, 'script']);
    return Script.fromJson(_jsonObject(response));
  }

  @override
  Future<QueueSummary> getQueueSummary() async {
    final response = await _sendJson('GET', ['queue']);
    return QueueSummary.fromJson(_jsonObject(response));
  }

  @override
  Future<AudioBytes> downloadProjectFinalAudio(
    String projectId, {
    String? range,
  }) {
    return _sendBytes(['projects', projectId, 'audio', 'final'], range: range);
  }

  @override
  Future<AudioBytes> streamProjectFinalAudio(
    String projectId, {
    String? range,
  }) {
    return _sendBytes(['projects', projectId, 'audio', 'stream'], range: range);
  }

  @override
  Future<AudioBytes> downloadJobFinalAudio(String jobId, {String? range}) {
    return _sendBytes(['jobs', jobId, 'audio', 'final'], range: range);
  }

  @override
  Future<AudioBytes> streamJobAudio(String jobId, {String? range}) {
    return _sendBytes(['jobs', jobId, 'audio', 'stream'], range: range);
  }

  @override
  Future<RuntimeSettings> getRuntimeSettings() async {
    final response = await _sendJson('GET', ['settings']);
    return RuntimeSettings.fromJson(_jsonObject(response));
  }

  @override
  Future<RuntimeSettings> updateRuntimeSettings(
    Map<String, Object> values,
  ) async {
    final response = await _sendJson(
      'PUT',
      ['settings'],
      body: {'values': values},
    );
    return RuntimeSettings.fromJson(_jsonObject(response));
  }

  @override
  Future<RuntimeStatus> reloadSettings() async {
    final response = await _sendJson('POST', ['settings', 'reload']);
    return RuntimeStatus.fromJson(_jsonObject(response));
  }

  @override
  Future<RuntimeStatus> getRuntimeStatus() async {
    final response = await _sendJson('GET', ['settings', 'runtime-status']);
    return RuntimeStatus.fromJson(_jsonObject(response));
  }

  @override
  Future<TtsEngineSettings> getTtsEngines() async {
    final response = await _sendJson('GET', ['settings', 'tts-engines']);
    return TtsEngineSettings.fromJson(_jsonObject(response));
  }

  @override
  Future<TtsEngineSettings> updateTtsEngine(String engine) async {
    final response = await _sendJson(
      'PUT',
      ['settings', 'tts-engine'],
      body: {'engine': engine},
    );
    return TtsEngineSettings.fromJson(_jsonObject(response));
  }

  @override
  Future<List<VoiceProfile>> listVoices() async {
    final response = await _sendJson('GET', ['voices']);
    return _jsonList(response, VoiceProfile.fromJson);
  }

  @override
  Future<VoiceProfile> uploadVoice({
    required String displayName,
    required String filename,
    required List<int> bytes,
  }) async {
    final request = http.MultipartRequest('POST', _uri(['voices']));
    request.headers['accept'] = 'application/json';
    request.fields['display_name'] = displayName;
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: _audioContentType(filename),
      ),
    );
    final response = _checkedResponse(
      await http.Response.fromStream(await _httpClient.send(request)),
    );
    return VoiceProfile.fromJson(_jsonObject(response));
  }

  Future<AudioBytes> _sendBytes(
    List<String> pathSegments, {
    String? range,
  }) async {
    final response = await _sendJson(
      'GET',
      pathSegments,
      headers: range == null ? null : {'range': range},
    );
    return AudioBytes(
      bytes: response.bodyBytes,
      statusCode: response.statusCode,
      headers: response.headers,
    );
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
    return _checkedResponse(
      await http.Response.fromStream(await _httpClient.send(request)),
    );
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
        message: response.body.isEmpty
            ? 'HTTP ${response.statusCode}'
            : response.body,
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
              .map(
                (item) =>
                    ValidationIssue.fromJson(item as Map<String, Object?>),
              )
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
    final baseSegments = _baseUrl.pathSegments.where(
      (segment) => segment.isNotEmpty,
    );
    return _baseUrl.replace(
      pathSegments: [...baseSegments, 'api', 'v1', ...pathSegments],
      queryParameters: queryParameters?.isEmpty ?? true
          ? null
          : queryParameters,
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
      if (entry.value != null && entry.value!.isNotEmpty)
        entry.key: entry.value!,
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

MediaType _audioContentType(String filename) {
  final extension = filename.split('.').last.toLowerCase();
  return switch (extension) {
    'wav' => MediaType('audio', 'wav'),
    'mp3' => MediaType('audio', 'mpeg'),
    'flac' => MediaType('audio', 'flac'),
    'm4a' => MediaType('audio', 'mp4'),
    _ => MediaType('application', 'octet-stream'),
  };
}
