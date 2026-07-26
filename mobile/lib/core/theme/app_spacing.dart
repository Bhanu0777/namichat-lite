import 'package:flutter/material.dart';

abstract final class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;

  static const EdgeInsets pagePadding = EdgeInsets.all(lg);
  static const EdgeInsets horizontalPadding = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets verticalPadding = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets listPadding = EdgeInsets.symmetric(horizontal: lg, vertical: md);

  static const SizedBox spaceXS = SizedBox(width: xs, height: xs);
  static const SizedBox spaceSM = SizedBox(width: sm, height: sm);
  static const SizedBox spaceMD = SizedBox(width: md, height: md);
  static const SizedBox spaceLG = SizedBox(width: lg, height: lg);
  static const SizedBox spaceXL = SizedBox(width: xl, height: xl);
}
