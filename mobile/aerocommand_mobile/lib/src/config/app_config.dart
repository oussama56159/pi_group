class AppConfig {
  /// Android emulator can reach host localhost via 10.0.2.2.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'ws://10.0.2.2:8000/api/v1/telemetry/ws',
  );

  /// Support email used for password recovery requests.
  /// Can be overridden at build time with: --dart-define=SUPPORT_EMAIL=...
  static const String supportEmail = String.fromEnvironment(
    'SUPPORT_EMAIL',
    defaultValue: 'touati.oussama@esprit.tn',
  );
}
