import 'package:namichat_lite/core/utils/env.dart';

/// Application-wide constants derived from [Env].
class AppConstants {
  const AppConstants._();

  static const String appName = 'NamiChat Lite';

  /// API version path segment, e.g. `/api/v1`.
  static String get apiVersion => Env.apiVersion;

  /// Fully-qualified REST base URL, e.g. `http://host:8000/api/v1`.
  static String get apiBaseUrl => '${Env.baseUrl}${Env.apiVersion}';

  /// Base URL for WebSocket connections (same host, `ws` scheme).
  static String get wsBaseUrl =>
      Env.baseUrl.replaceFirst(RegExp(r'^http'), 'ws');

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  static const String hiveBoxName = 'namichat_box';

  /// Storage key namespace prefix to avoid collisions.
  static const String storagePrefix = 'namichat_';
}
