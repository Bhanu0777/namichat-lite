import 'package:namichat_lite/features/groups/domain/entities/group.dart';

class GroupMemberModel {
  const GroupMemberModel({
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    required this.role,
    required this.joinedAt,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> j) => GroupMemberModel(
        userId:      j['user_id'] as String,
        username:    j['username'] as String,
        displayName: j['display_name'] as String?,
        avatarUrl:   j['avatar_url'] as String?,
        role:        j['role'] as String,
        joinedAt:    DateTime.parse(j['joined_at'] as String).toLocal(),
      );

  final String userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String role;
  final DateTime joinedAt;

  GroupMember toEntity() => GroupMember(
        userId:      userId,
        username:    username,
        displayName: displayName,
        avatarUrl:   avatarUrl,
        role:        role,
        joinedAt:    joinedAt,
      );
}

class GroupModel {
  const GroupModel({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    this.avatarUrl,
    required this.inviteCode,
    required this.createdAt,
    required this.updatedAt,
    this.members = const [],
    this.chatId,
  });

  factory GroupModel.fromJson(Map<String, dynamic> j) => GroupModel(
        id:          j['id'] as String,
        name:        j['name'] as String,
        description: j['description'] as String?,
        ownerId:     j['owner_id'] as String,
        avatarUrl:   j['avatar_url'] as String?,
        inviteCode:  j['invite_code'] as String,
        createdAt:   DateTime.parse(j['created_at'] as String).toLocal(),
        updatedAt:   DateTime.parse(j['updated_at'] as String).toLocal(),
        members: (j['members'] as List? ?? [])
            .map((m) => GroupMemberModel.fromJson(m as Map<String, dynamic>))
            .toList(),
        chatId: j['chat_id'] as String?,
      );

  final String id;
  final String name;
  final String? description;
  final String ownerId;
  final String? avatarUrl;
  final String inviteCode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<GroupMemberModel> members;
  final String? chatId;

  Group toEntity() => Group(
        id:          id,
        name:        name,
        description: description,
        ownerId:     ownerId,
        avatarUrl:   avatarUrl,
        inviteCode:  inviteCode,
        createdAt:   createdAt,
        updatedAt:   updatedAt,
        members:     members.map((m) => m.toEntity()).toList(),
        chatId:      chatId,
      );
}
