import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studycast/application/api_endpoint_settings_service.dart';
import 'package:studycast/infrastructure/settings/shared_preferences_api_endpoint_settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('resolves the default Android emulator backend URL', () async {
    final repository = SharedPreferencesApiEndpointSettingsRepository(
      await SharedPreferences.getInstance(),
    );
    final service = ApiEndpointSettingsService(repository);

    expect(await service.resolveBaseUrl(), Uri.parse('http://10.0.2.2:8000'));
  });

  test('persists a trimmed backend URL override', () async {
    final repository = SharedPreferencesApiEndpointSettingsRepository(
      await SharedPreferences.getInstance(),
    );
    final service = ApiEndpointSettingsService(repository);

    await service.saveBaseUrl('  http://192.168.1.42:8000/  ');

    expect(
      await service.resolveBaseUrl(),
      Uri.parse('http://192.168.1.42:8000'),
    );
  });

  test('rejects blank or relative backend URLs', () async {
    final repository = SharedPreferencesApiEndpointSettingsRepository(
      await SharedPreferences.getInstance(),
    );
    final service = ApiEndpointSettingsService(repository);

    expect(() => service.saveBaseUrl(''), throwsA(isA<FormatException>()));
    expect(
      () => service.saveBaseUrl('/api/v1'),
      throwsA(isA<FormatException>()),
    );
  });
}
