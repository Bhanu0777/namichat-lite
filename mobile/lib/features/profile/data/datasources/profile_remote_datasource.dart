
import 'package:namichat_lite/core/network/api_endpoints.dart';
import 'package:namichat_lite/core/network/dio_client.dart';
import 'package:namichat_lite/features/profile/data/models/profile_update_request_dto.dart';
import 'package:namichat_lite/features/profile/data/models/profile_user_model.dart';

class ProfileRemoteDataSource {
  ProfileRemoteDataSource(this._dioClient);

  final DioClient _dioClient;

  Future<ProfileUserModel> getProfile() async {
    final response = await _dioClient.client.get(ApiEndpoints.me);
    return ProfileUserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ProfileUserModel> updateProfile({
    String? email,
    String? username,
    String? fullName,
    String? displayName,
    String? namiId,
    String? bio,
    String? avatarUrl,
  }) async {
    final response = await _dioClient.client.patch(
      ApiEndpoints.me,
      data: ProfileUpdateRequestDto(
        email: email,
        username: username,
        fullName: fullName,
        displayName: displayName,
        namiId: namiId,
        bio: bio,
        avatarUrl: avatarUrl,
      ).toJson(),
    );
    return ProfileUserModel.fromJson(response.data as Map<String, dynamic>);
  }
}
