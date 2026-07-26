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

  static const double statusDot = 12.0;
  static const double microDot = 7.0;
  static const double tinyDot = 3.0;
  static const double tileIcon = 40.0;
  static const double logoSize = 36.0;
  static const double groupAvatar = 44.0;
  static const double iconButtonSize = 44.0;
  static const double iconSize = 20.0;
  static const double infoIcon = 18.0;
  static const double cameraIcon = 16.0;
  static const double inputIcon = 20.0;
  static const double sendButton = iconButtonSize;
  static const double buttonHeight = 48.0;
  static const double inputHeight = 52.0;
  static const double heroSize = 96.0;

  static const SizedBox spaceXS = SizedBox(width: xs, height: xs);
  static const SizedBox spaceSM = SizedBox(width: sm, height: sm);
  static const SizedBox spaceMD = SizedBox(width: md, height: md);
  static const SizedBox spaceLG = SizedBox(width: lg, height: lg);
  static const SizedBox spaceXL = SizedBox(width: xl, height: xl);
}
