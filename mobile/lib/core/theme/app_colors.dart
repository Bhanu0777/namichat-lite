import 'package:flutter/material.dart';

abstract final class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF4FC3F7);
  static const Color primaryDark = Color(0xFF2196F3);
  static const Color accent = Color(0xFF005A9C);
  static const Color background = Color(0xFFF8FAFC);
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color surface = Color(0xFF1E293B);
  static const Color surfaceVariant = Color(0xFF334155);
  static const Color cardBackground = Color(0xFF263548);
  static const Color border = Color(0xFF475569);
  static const Color text = Color(0xFFF8FAFC);
  static const Color primaryText = Color(0xFFF8FAFC);
  static const Color secondaryText = Color(0xFFCBD5E1);

  static const Color online = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color unreadBadge = Color(0xFF2196F3);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF4FC3F7), Color(0xFF2196F3), Color(0xFF005A9C)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient brandGradientHorizontal = LinearGradient(
    colors: [Color(0xFF4FC3F7), Color(0xFF2196F3), Color(0xFF005A9C)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: primaryDark,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE1F5FE),
      onPrimaryContainer: Color(0xFF0D47A1),
      secondary: primary,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFB3E5FC),
      onSecondaryContainer: Color(0xFF0064A5),
      tertiary: accent,
      onTertiary: Colors.white,
      error: error,
      onError: Colors.white,
      surface: background,
      onSurface: Color(0xFF1E293B),
      surfaceContainerHighest: Color(0xFFE2E8F0),
      onSurfaceVariant: Color(0xFF475569),
      outline: Color(0xFFCBD5E1),
      outlineVariant: Color(0xFFE2E8F0),
    );
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: darkBackground,
      primaryContainer: Color(0xFF0B3A47),
      onPrimaryContainer: Color(0xFF4FC3F7),
      secondary: primaryDark,
      onSecondary: darkBackground,
      secondaryContainer: Color(0xFF0E4A54),
      onSecondaryContainer: Color(0xFF2196F3),
      tertiary: accent,
      onTertiary: Colors.white,
      error: error,
      onError: Colors.white,
      surface: darkBackground,
      onSurface: primaryText,
      surfaceContainerHighest: darkSurface,
      onSurfaceVariant: secondaryText,
      outline: surfaceVariant,
      outlineVariant: darkSurface,
    );
  }
}
