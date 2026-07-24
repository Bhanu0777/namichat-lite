import 'package:flutter/material.dart';

/// Flow color palette — an ocean-wave inspired set of brand and semantic tones.
///
/// Use [FlowColors.scheme] to derive a Material 3 [ColorScheme] for the
/// [FlowTheme] light/dark themes, or reference the named tones directly for
/// custom painting.
class FlowColors {
  const FlowColors._();

  // ---- Ocean brand scale (deep → foam) ----
  static const Color deepOcean = Color(0xFF06283D);
  static const Color ocean = Color(0xFF0E7C9B);
  static const Color sea = Color(0xFF1CA0B0);
  static const Color aqua = Color(0xFF63D2C7);
  static const Color tide = Color(0xFFBFE3E0);
  static const Color foam = Color(0xFFEAF7F6);

  // ---- Semantic ----
  static const Color success = Color(0xFF2BB673);
  static const Color warning = Color(0xFFF0A500);
  static const Color danger = Color(0xFFE5484D);
  static const Color info = Color(0xFF1CA0B0);

  // ---- Neutrals ----
  static const Color ink = Color(0xFF0B1F2B);
  static const Color mist = Color(0xFF6B8595);

  /// Builds a complete [ColorScheme] tuned for the given brightness.
  static ColorScheme scheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    return ColorScheme(
      brightness: brightness,
      primary: isLight ? ocean : sea,
      onPrimary: isLight ? Colors.white : deepOcean,
      primaryContainer: isLight ? tide : const Color(0xFF0B3A47),
      onPrimaryContainer: isLight ? deepOcean : aqua,
      secondary: isLight ? sea : aqua,
      onSecondary: isLight ? Colors.white : deepOcean,
      secondaryContainer: isLight ? foam : const Color(0xFF0E4A54),
      onSecondaryContainer: isLight ? deepOcean : tide,
      tertiary: isLight ? aqua : tide,
      onTertiary: isLight ? deepOcean : deepOcean,
      error: danger,
      onError: Colors.white,
      errorContainer: isLight ? const Color(0xFFFBE4E5) : const Color(0xFF3A1417),
      onErrorContainer: isLight ? const Color(0xFF410E11) : const Color(0xFFFBCED0),
      surface: isLight ? foam : deepOcean,
      onSurface: isLight ? ink : foam,
      surfaceContainerHighest: isLight ? foam : const Color(0xFF12303B),
      onSurfaceVariant: isLight ? mist : tide,
      outline: isLight ? tide : const Color(0xFF2C5562),
      outlineVariant: isLight ? const Color(0xFFD6EAE8) : const Color(0xFF1C3B47),
      shadow: isLight ? deepOcean : Colors.black,
      scrim: Colors.black54,
      inverseSurface: isLight ? deepOcean : Colors.white,
      onInverseSurface: isLight ? Colors.white : deepOcean,
      inversePrimary: isLight ? aqua : ocean,
    );
  }

  /// A soft vertical gradient evoking a receding ocean wave.
  static LinearGradient waveGradient(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isLight
          ? [foam, tide, aqua.withValues(alpha: 0.35)]
          : [deepOcean, const Color(0xFF0B3A47), ocean.withValues(alpha: 0.4)],
    );
  }
}
