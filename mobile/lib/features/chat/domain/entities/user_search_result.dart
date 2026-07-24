import 'package:equatable/equatable.dart';

/// Domain entity for a user returned by the search endpoint.
///
/// [existingChatId] is non-null when a direct chat already exists between
/// the current user and this person. If null, a chat must be created on tap
/// via the open-chat endpoint.
class UserSearchResult extends Equatable {
  const UserSearchResult({
    required this.id,
    required this.username,
    this.fullName,
    this.displayName,
    this.namiId,
    this.avatarUrl,
    this.bio,
    this.existingChatId,
  });

  final String id;
  final String username;
  final String? fullName;
  final String? displayName;
  final String? namiId;
  final String? avatarUrl;
  final String? bio;

  /// ID of the direct chat that already exists, or null if none yet.
  final String? existingChatId;

  /// The human-readable name to show in the UI.
  String get displayLabel => displayName ?? fullName ?? username;

  /// Whether a chat already exists with this user.
  bool get hasChatAlready => existingChatId != null;

  @override
  List<Object?> get props => [
        id,
        username,
        fullName,
        displayName,
        namiId,
        avatarUrl,
        bio,
        existingChatId,
      ];
}
