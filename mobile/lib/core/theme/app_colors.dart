import 'package:flutter/material.dart';

abstract final class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF4FC3F7);
  static const Color primaryDark = Color(0xFF2196F3);
  static const Color accent = Color(0xFF005A9C);
  static const Color background = Color(0xFFF8FAFC);
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color surface = Color(0xFF1E293B);
  static const Color surfaceVariant = Color(0xFF334155);
  static const Color text = Color(0xFFF8FAFC);
  static const Color secondaryText = Color(0xFFCBD5E1);

  static ColorScheme lightScheme() {
    return ColorScheme(
      brightness: Brightness.light,
      primary: primaryDark,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFE1F5FE),
      onPrimaryContainer: const Color(0xFF0D47A1),
      secondary: primary,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFB3E5FC),
      onSecondaryContainer: const Color(0xFF0064A5),
      tertiary: accent,
      onTertiary: Colors.white,
      error: const Color(0xFFEF4444),
      onError: Colors.white,
      surface: background,
      onSurface: const Color(0xFF1E293B),
      surfaceContainerHighest: const Color(0xFFE2E8F0),
      onSurfaceVariant: const Color(0xFF475569),
      outline: const Color(0xFFCBD5E1),
      outlineVariant: const Color(0xFFE2E8F0),
    );
  }

  static ColorScheme darkScheme() {
    return ColorScheme(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: darkBackground,
      primaryContainer: const Color(0xFF0B3A47),
      onPrimaryContainer: const Color(0xFF4FC3F7),
      secondary: primaryDark,
      onSecondary: darkBackground,
      secondaryContainer: const Color(0xFF0E4A54),
      onSecondaryContainer: const Color(0xFF2196F3),
      tertiary: accent,
      onTertiary: Colors.white,
      error: const Color(0xFFEF4444),
      onError: Colors.white,
      surface: darkBackground,
      onSurface: text,
      surfaceContainerHighest: surface,
      onSurfaceVariant: secondaryText,
      outline: surfaceVariant,
      outlineVariant: surface,
    );
  }
}
