import 'package:shared_preferences/shared_preferences.dart';
import 'package:studycast/domain/settings/api_endpoint_settings_repository.dart';

class SharedPreferencesApiEndpointSettingsRepository
    implements ApiEndpointSettingsRepository {
  SharedPreferencesApiEndpointSettingsRepository(this._preferences);

  static const _baseUrlKey = 'studycast.api.base_url';

  final SharedPreferences _preferences;

  @override
  Future<Uri?> loadBaseUrlOverride() async {
    final stored = _preferences.getString(_baseUrlKey);
    if (stored == null || stored.isEmpty) {
      return null;
    }
    return Uri.parse(stored);
  }

  @override
  Future<void> saveBaseUrlOverride(Uri baseUrl) async {
    await _preferences.setString(_baseUrlKey, baseUrl.toString());
  }
}
