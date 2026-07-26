import 'package:flutter/material.dart';

/// NamiChat Lite corner radius tokens.
///
/// Use with [RoundedRectangleBorder], [BorderRadius.circular], or any
/// Material 3 shape configuration.
class AppRadius {
  const AppRadius._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 28.0;
  static const double full = 999.0;

  static const BorderRadius button = BorderRadius.all(Radius.circular(md));
  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius dialog = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius input = BorderRadius.all(Radius.circular(md));
  static const BorderRadius chip = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius fab = BorderRadius.all(Radius.circular(full));
}
