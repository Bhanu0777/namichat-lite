/// Compile-time environment configuration.
///
/// Values are injected via `--dart-define` at build time, e.g.:
///   flutter run --dart-define=BASE_URL=https://api.example.com
///   flutter run --dart-define=APP_ENV=production
class Env {
  const Env._();

  static const String appEnv =
      String.fromEnvironment('APP_ENV', defaultValue: 'development');

  /// Compile-time override. If provided via --dart-define, it takes priority.
  static const String _baseUrlOverride =
      String.fromEnvironment('BASE_URL', defaultValue: '');

  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) return _baseUrlOverride;
    return 'https://namichat-lite.onrender.com';
  }

  static const String apiVersion =
      String.fromEnvironment('API_VERSION', defaultValue: '/api/v1');

  static const bool enableLogging =
      bool.fromEnvironment('ENABLE_LOGGING', defaultValue: true);

  static bool get isProduction => appEnv == 'production';
  static bool get isDevelopment => appEnv == 'development';
}
