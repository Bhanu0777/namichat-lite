import 'package:equatable/equatable.dart';

class ProfileUser extends Equatable {
  const ProfileUser({
    required this.id,
    required this.email,
    required this.username,
    this.displayName,
    this.namiId,
    this.bio,
    this.avatarUrl,
    this.fullName,
    this.isActive = true,
    required this.createdAt,
  });

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

  @override
  List<Object?> get props => [
        id,
        email,
        username,
        displayName,
        namiId,
        bio,
        avatarUrl,
        fullName,
        isActive,
        createdAt,
      ];
}
