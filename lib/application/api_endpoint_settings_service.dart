import 'package:studycast/domain/settings/api_endpoint_settings_repository.dart';

class ApiEndpointSettingsService {
  ApiEndpointSettingsService(this._repository, {Uri? defaultBaseUrl})
    : _defaultBaseUrl = defaultBaseUrl ?? _environmentDefaultBaseUrl;

  static final Uri _environmentDefaultBaseUrl = Uri.parse(
    const String.fromEnvironment(
      'STUDYCAST_API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8000',
    ),
  );

  final ApiEndpointSettingsRepository _repository;
  final Uri _defaultBaseUrl;

  Future<Uri> resolveBaseUrl() async {
    return await _repository.loadBaseUrlOverride() ?? _defaultBaseUrl;
  }

  Future<void> saveBaseUrl(String value) async {
    final parsed = Uri.tryParse(value.trim());
    if (parsed == null || !parsed.hasScheme || parsed.host.isEmpty) {
      throw FormatException(
        'Backend URL must be an absolute HTTP(S) URL.',
        value,
      );
    }
    if (parsed.scheme != 'http' && parsed.scheme != 'https') {
      throw FormatException('Backend URL must use HTTP or HTTPS.', value);
    }
    await _repository.saveBaseUrlOverride(_withoutTrailingSlash(parsed));
  }

  Uri _withoutTrailingSlash(Uri uri) {
    final text = uri.toString();
    if (text.length > uri.origin.length && text.endsWith('/')) {
      return Uri.parse(text.substring(0, text.length - 1));
    }
    return uri;
  }
}
