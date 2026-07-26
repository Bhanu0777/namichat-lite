import 'package:flutter/material.dart';

abstract final class AppRadius {
  AppRadius._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 28.0;
  static const double full = 999.0;

  static BorderRadius get button => const BorderRadius.all(Radius.circular(md));
  static BorderRadius get card => const BorderRadius.all(Radius.circular(lg));
  static BorderRadius get dialog => const BorderRadius.all(Radius.circular(xl));
  static BorderRadius get input => const BorderRadius.all(Radius.circular(md));
  static BorderRadius get chip => const BorderRadius.all(Radius.circular(sm));
  static BorderRadius get fab => const BorderRadius.all(Radius.circular(full));
}
