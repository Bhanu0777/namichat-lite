import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

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

  /// Resolved base URL.
  ///
  /// - If `--dart-define=BASE_URL=...` was supplied, that value is used.
  /// - On Android (emulator) the host machine is reachable via `10.0.2.2`.
  /// - On web, iOS simulator, macOS, Windows and Linux use `localhost`.
  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) return _baseUrlOverride;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    // Use 127.0.0.1 instead of localhost to avoid IPv6 resolution issues
    // on Windows desktop Flutter apps.
    return 'http://127.0.0.1:8000';
  }

  static const String apiVersion =
      String.fromEnvironment('API_VERSION', defaultValue: '/api/v1');

  static const bool enableLogging =
      bool.fromEnvironment('ENABLE_LOGGING', defaultValue: true);

  static bool get isProduction => appEnv == 'production';
  static bool get isDevelopment => appEnv == 'development';
}
