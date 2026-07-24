import 'package:namichat_lite/core/network/api_endpoints.dart';
import 'package:namichat_lite/core/network/dio_client.dart';
import 'package:namichat_lite/features/groups/data/models/group_model.dart';

class GroupRemoteDataSource {
  GroupRemoteDataSource(this._client);

  final DioClient _client;

  Future<GroupModel> createGroup({
    required String name,
    String? description,
    String? avatarUrl,
  }) async {
    final res = await _client.client.post(
      ApiEndpoints.groups,
      data: {
        'name': name,
        if (description != null) 'description': description,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      },
    );
    return GroupModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<GroupModel>> listMyGroups() async {
    final res = await _client.client.get(ApiEndpoints.groups);
    return (res.data as List)
        .map((j) => GroupModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<GroupModel> getGroup(String groupId) async {
    final res = await _client.client.get(ApiEndpoints.group(groupId));
    return GroupModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<GroupModel> updateGroup(
    String groupId, {
    String? name,
    String? description,
    String? avatarUrl,
  }) async {
    final res = await _client.client.patch(
      ApiEndpoints.group(groupId),
      data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      },
    );
    return GroupModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteGroup(String groupId) =>
      _client.client.delete(ApiEndpoints.group(groupId));

  Future<GroupModel> joinByCode(String inviteCode) async {
    final res = await _client.client.post(
      ApiEndpoints.groupsJoin,
      data: {'invite_code': inviteCode},
    );
    return GroupModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<String> regenerateInviteCode(String groupId) async {
    final res = await _client.client
        .post(ApiEndpoints.groupRegenerateInvite(groupId));
    return (res.data as Map<String, dynamic>)['invite_code'] as String;
  }

  Future<void> removeMember(String groupId, String userId) =>
      _client.client.delete(ApiEndpoints.groupMember(groupId, userId));

  Future<void> promoteMember(String groupId, String userId) =>
      _client.client.post(ApiEndpoints.groupPromoteMember(groupId, userId));
}
