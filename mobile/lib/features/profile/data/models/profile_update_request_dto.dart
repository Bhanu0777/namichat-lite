class ProfileUpdateRequestDto {
  const ProfileUpdateRequestDto({
    this.email,
    this.username,
    this.fullName,
    this.displayName,
    this.namiId,
    this.bio,
    this.avatarUrl,
  });

  final String? email;
  final String? username;
  final String? fullName;
  final String? displayName;
  final String? namiId;
  final String? bio;
  final String? avatarUrl;

  Map<String, dynamic> toJson() => {
        if (email != null) 'email': email,
        if (username != null) 'username': username,
        if (fullName != null) 'full_name': fullName,
        if (displayName != null) 'display_name': displayName,
        if (namiId != null) 'nami_id': namiId,
        if (bio != null) 'bio': bio,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      };
}
