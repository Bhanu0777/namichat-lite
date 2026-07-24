class ProfileValidators {
  const ProfileValidators._();

  static String? required(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  static String? email(String? value) {
    final message = required(value, label: 'Email');
    if (message != null) return message;
    if (!value!.trim().contains('@')) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? username(String? value) {
    final message = required(value, label: 'Username');
    if (message != null) return message;
    if (value!.trim().length < 3) {
      return 'Username must be at least 3 characters';
    }
    return null;
  }

  static String? namiId(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final cleaned = value.trim();
    if (cleaned.length < 3) return 'Nami ID must be at least 3 characters';
    if (!RegExp(r'^[a-z0-9-]+$').hasMatch(cleaned)) {
      return 'Use lowercase letters, numbers, or dashes';
    }
    return null;
  }

  static String? bio(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (value.trim().length > 160) return 'Bio can be at most 160 characters';
    return null;
  }
}
