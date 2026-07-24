import 'package:namichat_lite/features/profile/domain/entities/profile_user.dart';

class ProfileUserModel {
  const ProfileUserModel({
    required this.id,
    required this.email,
    required this.username,
    this.displayName,
    this.namiId,
    this.bio,
    this.avatarUrl,
    this.fullName,
    required this.isActive,
    required this.createdAt,
  });

  factory ProfileUserModel.fromJson(Map<String, dynamic> json) {
    return ProfileUserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String?,
      namiId: json['nami_id'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      fullName: json['full_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String email;
  final String username;
  final String? displayName;
  final String? namiId;
  final String? bio;
  final String? avatarUrl;
  final String? fullName;
  final bool isActive;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'username': username,
        'display_name': displayName,
        'nami_id': namiId,
        'bio': bio,
        'avatar_url': avatarUrl,
        'full_name': fullName,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
      };

  ProfileUser toEntity() => ProfileUser(
        id: id,
        email: email,
        username: username,
        displayName: displayName,
        namiId: namiId,
        bio: bio,
        avatarUrl: avatarUrl,
        fullName: fullName,
        isActive: isActive,
        createdAt: createdAt,
      );
}
