import 'package:flutter/material.dart';



/// Flow typography — a calm, legible type ramp tuned for ocean-themed UIs.
///
/// Use [FlowTypography.build] to generate a full [TextTheme] bound to a
/// [ColorScheme], or reference the named static styles directly.
class FlowTypography {
  const FlowTypography._();

  /// Optional global font family. Defaults to the platform font.
  static const String? fontFamily = null;

  static TextTheme build(ColorScheme scheme) {
    final body = scheme.onSurface;
    final muted = scheme.onSurfaceVariant;
    final TextStyle base = TextStyle(
      fontFamily: fontFamily,
      color: body,
      fontWeight: FontWeight.w400,
      height: 1.4,
    );

    return TextTheme(
      displayLarge: base.copyWith(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -0.5,
      ),
      displayMedium: base.copyWith(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.25,
      ),
      displaySmall: base.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
      headlineLarge: base.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      headlineMedium: base.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      headlineSmall: base.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      titleLarge: base.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
      titleSmall: base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      bodyLarge: base.copyWith(fontSize: 16, color: body),
      bodyMedium: base.copyWith(fontSize: 14, color: body),
      bodySmall: base.copyWith(fontSize: 12, color: muted),
      labelLarge: base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
      labelSmall: base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: muted,
      ),
    );
  }

  // ---- Convenience styles ----
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
