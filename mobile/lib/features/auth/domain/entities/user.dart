import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.username,
    this.fullName,
    this.avatarUrl,
    this.isActive = true,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final bool isActive;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        email,
        username,
        fullName,
        avatarUrl,
        isActive,
        createdAt,
      ];
}

class AuthTokens extends Equatable {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'bearer',
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;

  @override
  List<Object?> get props => [accessToken, refreshToken, tokenType];
}
