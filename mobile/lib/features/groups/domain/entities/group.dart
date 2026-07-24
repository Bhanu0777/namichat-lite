import 'package:equatable/equatable.dart';

class GroupMember extends Equatable {
  const GroupMember({
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    required this.role,
    required this.joinedAt,
  });

  final String userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String role; // 'admin' | 'member'
  final DateTime joinedAt;

  bool get isAdmin => role == 'admin';
  String get displayLabel => displayName ?? username;

  @override
  List<Object?> get props =>
      [userId, username, displayName, avatarUrl, role, joinedAt];
}

class Group extends Equatable {
  const Group({
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

  final String id;
  final String name;
  final String? description;
  final String ownerId;
  final String? avatarUrl;
  final String inviteCode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<GroupMember> members;
  final String? chatId;

  int get memberCount => members.length;
  bool isOwner(String userId) => ownerId == userId;
  bool isAdmin(String userId) =>
      members.any((m) => m.userId == userId && m.isAdmin);

  @override
  List<Object?> get props => [
        id, name, description, ownerId, avatarUrl,
        inviteCode, createdAt, updatedAt, members, chatId,
      ];
}
