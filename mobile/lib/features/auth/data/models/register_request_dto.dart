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
