import 'package:namichat_lite/features/chat/domain/entities/user_search_result.dart';

class UserSearchResultModel {
  const UserSearchResultModel({
    required this.id,
    required this.username,
    this.fullName,
    this.displayName,
    this.namiId,
    this.avatarUrl,
    this.bio,
    this.existingChatId,
  });

  factory UserSearchResultModel.fromJson(Map<String, dynamic> json) {
    return UserSearchResultModel(
      id: json['id'] as String,
      username: json['username'] as String,
      fullName: json['full_name'] as String?,
      displayName: json['display_name'] as String?,
      namiId: json['nami_id'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      existingChatId: json['existing_chat_id'] as String?,
    );
  }

  final String id;
  final String username;
  final String? fullName;
  final String? displayName;
  final String? namiId;
  final String? avatarUrl;
  final String? bio;
  final String? existingChatId;

  UserSearchResult toEntity() => UserSearchResult(
        id: id,
        username: username,
        fullName: fullName,
        displayName: displayName,
        namiId: namiId,
        avatarUrl: avatarUrl,
        bio: bio,
        existingChatId: existingChatId,
      );
}
