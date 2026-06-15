abstract interface class ApiEndpointSettingsRepository {
  Future<Uri?> loadBaseUrlOverride();

  Future<void> saveBaseUrlOverride(Uri baseUrl);
}
