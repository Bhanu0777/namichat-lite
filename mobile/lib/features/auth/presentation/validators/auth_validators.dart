class AuthValidators {
  const AuthValidators._();

  static String? required(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  static String? email(String? value) {
    final message = required(value, label: 'Email');
    if (message != null) return message;
    final trimmed = value!.trim();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(trimmed)) {
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

  static String? password(String? value, {int minLength = 8}) {
    final message = required(value, label: 'Password');
    if (message != null) return message;
    if (value!.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }
}
