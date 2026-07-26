import 'package:flutter/material.dart';

/// NamiChat Lite typography system — Material 3 type ramp with ocean-themed tuning.
///
/// Use [AppTypography.textTheme] to generate a full [TextTheme] bound to a
/// [ColorScheme], or reference the named styles directly.
class AppTypography {
  const AppTypography._();

  static const String? _fontFamily = null;

  static TextTheme textTheme(ColorScheme scheme) {
    final Color onSurface = scheme.onSurface;
    final Color onSurfaceVariant = scheme.onSurfaceVariant;

    const TextStyle base = TextStyle(
      fontFamily: _fontFamily,
      height: 1.4,
    );

    return TextTheme(
      displayLarge: base.copyWith(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.5,
        color: onSurface,
      ),
      displayMedium: base.copyWith(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.25,
        color: onSurface,
      ),
      displaySmall: base.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: onSurface,
      ),
      headlineLarge: base.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: onSurface,
      ),
      headlineMedium: base.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: onSurface,
      ),
      headlineSmall: base.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: onSurface,
      ),
      titleLarge: base.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleMedium: base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: onSurface,
      ),
      titleSmall: base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: onSurface,
      ),
      bodyLarge: base.copyWith(fontSize: 16, color: onSurface),
      bodyMedium: base.copyWith(fontSize: 14, color: onSurface),
      bodySmall: base.copyWith(fontSize: 12, color: onSurfaceVariant),
      labelLarge: base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: onSurface,
      ),
      labelMedium: base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: onSurface,
      ),
      labelSmall: base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: onSurfaceVariant,
      ),
    );
  }

  static const TextStyle heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
}
