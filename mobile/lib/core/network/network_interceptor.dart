import 'package:dio/dio.dart';

import 'package:namichat_lite/core/errors/failures.dart';
import 'package:namichat_lite/core/network/api_endpoints.dart';
import 'package:namichat_lite/core/storage/secure_storage.dart';
import 'package:namichat_lite/core/storage/storage_keys.dart';

/// Injects the bearer token into outgoing requests and transparently refreshes
/// the access token on 401 responses using the stored refresh token.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._secureStorage);

  final SecureStorage _secureStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.read(StorageKeys.accessToken);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final refresh = await _secureStorage.read(StorageKeys.refreshToken);
      if (refresh != null) {
        try {
          final response = await Dio().post(
            '${err.requestOptions.baseUrl}${ApiEndpoints.refresh}',
            data: {'refresh_token': refresh},
            options: Options(
              contentType: Headers.jsonContentType,
              headers: {'Content-Type': 'application/json'},
            ),
          );
          final newAccess = response.data['access_token'] as String;
          final newRefresh = response.data['refresh_token'] as String;
          await _secureStorage.write(StorageKeys.accessToken, newAccess);
          await _secureStorage.write(StorageKeys.refreshToken, newRefresh);

          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newAccess';
          final retry = await Dio().fetch(opts);
          return handler.resolve(retry);
        } catch (_) {
          // Allow the original 401 to propagate.
        }
      }
    }
    handler.next(err);
  }
}

/// Translates Dio transport errors into domain [Failure] types.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final failure = _mapError(err);
    handler.next(err.copyWith(error: failure));
  }

  Failure _mapError(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.badResponse:
        final code = err.response?.statusCode ?? 0;
        final message = _extractMessage(err.response);
        if (code == 401) return AuthFailure(message, code);
        return ServerFailure(message, code);
      default:
        return const ServerFailure('Unexpected error occurred');
    }
  }

  String _extractMessage(Response? response) {
    if (response?.data is Map<String, dynamic>) {
      final data = response!.data as Map<String, dynamic>;
      if (data case {'detail': final String detail}) return detail;
      if (data case {'message': final String message}) return message;
    }
    return 'Request failed';
  }
}
