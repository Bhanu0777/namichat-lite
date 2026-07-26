import 'package:flutter/material.dart';

abstract final class AppGradients {
  AppGradients._();

  static const LinearGradient brand = LinearGradient(
    colors: [Color(0xFF4FC3F7), Color(0xFF2196F3), Color(0xFF005A9C)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient brandHorizontal = LinearGradient(
    colors: [Color(0xFF4FC3F7), Color(0xFF2196F3), Color(0xFF005A9C)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient wave = LinearGradient(
    colors: [Color(0xFF2196F3), Color(0xFF4FC3F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient ocean = LinearGradient(
    colors: [Color(0xFF0D47A1), Color(0xFF4FC3F7)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
