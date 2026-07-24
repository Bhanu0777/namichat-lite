class RegisterRequestDto {
  const RegisterRequestDto({
    required this.email,
    required this.username,
    required this.password,
    this.fullName,
  });

  final String email;
  final String username;
  final String password;
  final String? fullName;

  Map<String, dynamic> toJson() => {
        'email': email,
        'username': username,
        'password': password,
        if (fullName != null && fullName!.isNotEmpty) 'full_name': fullName,
      };
}


class RegisterResponseDto {
  const RegisterResponseDto({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'bearer',
  });

  factory RegisterResponseDto.fromJson(Map<String, dynamic> json) {
    return RegisterResponseDto(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: (json['token_type'] as String?) ?? 'bearer',
    );
  }

  final UserModel user;
  final String accessToken;
  final String refreshToken;
  final String tokenType;
}
