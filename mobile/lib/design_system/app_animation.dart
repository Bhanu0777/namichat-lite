import 'package:flutter/material.dart';

/// NamiChat Lite motion system — durations and curves.
///
/// Use these constants to keep transitions consistent across the app.
class AppAnimation {
  const AppAnimation._();

  // ---- Durations ----
  static const Duration instant = Duration(milliseconds: 50);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration splash = Duration(milliseconds: 2200);

  // ---- Curves ----
  static const Curve standard = Curves.easeInOut;
  static const Curve decelerate = Curves.easeOut;
  static const Curve accelerate = Curves.easeIn;
  static const Curve sharp = Curves.easeInOutCubic;
  static const Curve gentle = Curves.easeInOutSine;

  // ---- Common transitions ----
  static const Duration pageTransition = medium;
  static const Duration fadeTransition = medium;
  static const Duration slideTransition = fast;
  static const Duration scaleTransition = fast;
  static const Duration buttonPress = fast;

  // ---- Stagger helpers ----
  static Duration delay(int index, {Duration base = fast}) {
    return base * index;
  }
}
