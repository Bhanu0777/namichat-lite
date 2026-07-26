import 'package:flutter/material.dart';

import 'package:namichat_lite/core/theme/app_radius.dart';
import 'package:namichat_lite/core/theme/app_spacing.dart';

/// Flow spacing, radii, and insets — an 8pt-aligned scale for consistent rhythm.
class FlowSpacing {
  const FlowSpacing._();

  // ---- Spacing scale ----
  static const double xs = AppSpacing.xs;
  static const double sm = AppSpacing.sm;
  static const double md = AppSpacing.md;
  static const double lg = AppSpacing.lg;
  static const double xl = AppSpacing.xl;
  static const double xxl = AppSpacing.xxl;
  static const double xxxl = AppSpacing.xxxl;

  // ---- Radii ----
  static const double radiusSm = AppRadius.radiusSm;
  static const double radiusMd = AppRadius.radiusMd;
  static const double radiusLg = AppRadius.radiusLg;
  static const double radiusXl = AppRadius.radiusXl;
  static const double radiusFull = AppRadius.radiusFull;

  // ---- Common insets ----
  static const EdgeInsets screenPadding = AppSpacing.pagePadding;
  static const EdgeInsets cardPadding = AppSpacing.cardPadding;
  static const EdgeInsets listPadding = AppSpacing.listPadding;

  // ---- Component sizing ----
  static const double buttonHeight = AppSpacing.buttonHeight;
  static const double iconButtonSize = AppSpacing.iconButtonSize;
  static const double inputHeight = AppSpacing.inputHeight;
}
