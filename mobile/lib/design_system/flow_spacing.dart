import 'package:flutter/material.dart';

/// Flow spacing, radii, and insets — an 8pt-aligned scale for consistent rhythm.
class FlowSpacing {
  const FlowSpacing._();

  // ---- Spacing scale ----
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;

  // ---- Radii ----
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 20.0;
  static const double radiusXl = 28.0;
  static const double radiusFull = 999.0;

  // ---- Common insets ----
  static const EdgeInsets screenPadding = EdgeInsets.all(lg);
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets listPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  // ---- Component sizing ----
  static const double buttonHeight = 48.0;
  static const double iconButtonSize = 44.0;
  static const double inputHeight = 52.0;
}
