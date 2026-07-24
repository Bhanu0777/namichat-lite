
import 'package:namichat_lite/core/network/api_endpoints.dart';
import 'package:namichat_lite/core/network/dio_client.dart';
import 'package:namichat_lite/features/auth/data/models/auth_token_model.dart';
import 'package:namichat_lite/features/auth/data/models/login_request_dto.dart';
import 'package:namichat_lite/features/auth/data/models/refresh_request_dto.dart';
import 'package:namichat_lite/features/auth/data/models/register_request_dto.dart';
import 'package:namichat_lite/features/auth/data/models/user_model.dart';

/// Remote data source for authentication backed by the FastAPI backend.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dioClient);

  final DioClient _dioClient;

  Future<AuthTokenModel> login(String identifier, String password) async {
    final response = await _dioClient.client.post(
      ApiEndpoints.login,
      data: LoginRequestDto(identifier: identifier, password: password).toJson(),
    );
    return AuthTokenModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserModel> register({
    required String email,
    required String username,
    required String password,
    String? fullName,
  }) async {
    final response = await _dioClient.client.post(
      ApiEndpoints.register,
      data: RegisterRequestDto(
        email: email,
        username: username,
        password: password,
        fullName: fullName,
      ).toJson(),
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserModel> getProfile() async {
    final response = await _dioClient.client.get(ApiEndpoints.me);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AuthTokenModel> refresh(String refreshToken) async {
    final response = await _dioClient.client.post(
      ApiEndpoints.refresh,
      data: RefreshRequestDto(refreshToken: refreshToken).toJson(),
    );
    return AuthTokenModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _dioClient.client.post(ApiEndpoints.logout);
  }
}
