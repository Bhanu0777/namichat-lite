import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'package:namichat_lite/core/constants/app_constants.dart';
import 'package:namichat_lite/core/utils/env.dart';
import 'package:namichat_lite/core/storage/secure_storage.dart';
import 'package:namichat_lite/core/storage/storage_keys.dart';
import 'package:namichat_lite/core/network/network_interceptor.dart';

/// Centralized Dio client factory with auth + error + logging interceptors.
class DioClient {
  DioClient(this._secureStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    )..interceptors.addAll([
        AuthInterceptor(_secureStorage),
        ErrorInterceptor(),
        if (Env.enableLogging)
          PrettyDioLogger(
            requestHeader: true,
            requestBody: true,
            responseBody: true,
            responseHeader: false,
            error: true,
            compact: true,
          ),
      ]);
  }

  final SecureStorage _secureStorage;
  late final Dio _dio;

  Dio get client => _dio;

  /// Caches a freshly issued access token after a refresh.
  Future<void> setAccessToken(String token) async {
    await _secureStorage.write(StorageKeys.accessToken, token);
  }
}
