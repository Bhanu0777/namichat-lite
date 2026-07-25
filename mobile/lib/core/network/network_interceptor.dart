import 'dart:io';

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
    final String message;
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Request timed out. Please try again.';
        break;
      case DioExceptionType.connectionError:
        final underlying = err.error;
        final isSocket = underlying is SocketException;
        final isHandshake = err.message?.contains('HandshakeException') ?? false;
        final isTls = (err.message?.contains('TLS') ?? false) || (err.message?.contains('SSL') ?? false);
        if (isSocket) {
          message = 'No internet connection.';
        } else if (isHandshake || isTls) {
          message = 'Secure connection failed.';
        } else {
          message = 'Connection error. Please check your internet.';
        }
        break;
      case DioExceptionType.badResponse:
        final code = err.response?.statusCode ?? 0;
        final apiMessage = _extractMessage(err.response);
        switch (code) {
          case 401:
            return AuthFailure(apiMessage.isEmpty ? 'Invalid email or password' : apiMessage, code);
          case 403:
            return ServerFailure(apiMessage.isEmpty ? 'Access denied' : apiMessage, code);
          case 404:
            return ServerFailure(apiMessage.isEmpty ? 'Service not found' : apiMessage, code);
          case 422:
            return ServerFailure(apiMessage.isEmpty ? 'Please check your input' : apiMessage, code);
          case 429:
            return ServerFailure('Too many attempts. Please wait and try again.', code);
          case 500:
          case 502:
          case 503:
            return ServerFailure(apiMessage.isEmpty ? 'Server error. Please try again later.' : apiMessage, code);
          default:
            return ServerFailure(apiMessage.isEmpty ? 'Request failed' : apiMessage, code);
        }
      case DioExceptionType.cancel:
        message = 'Request was cancelled.';
        break;
      case DioExceptionType.unknown:
      default:
        final underlying = err.error;
        if (underlying is SocketException) {
          message = 'No internet connection.';
        } else {
          message = 'Unexpected error occurred.';
        }
    }

    return ServerFailure(message, err.response?.statusCode);
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
