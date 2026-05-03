import 'package:flutter/material.dart';

class AppSpacing {
  // 🔹 Base 8pt Grid Tokens
  static const double xs = 4;    // micro
  static const double sm = 8;    // tight
  static const double md = 12;   // compact
  static const double lg = 16;   // default
  static const double xl = 20;   // medium
  static const double xxl = 24;  // large
  static const double hero = 32; // hero

  // 🔹 Standardized Page Padding
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: lg, // 16
    vertical: lg,   // 16
  );

  // 🔹 Component Gaps
  static const double gapInput = lg; // 16
  static const double gapLabel = sm; // 8
  static const double gapCard = lg;  // 16
  static const double gapSection = xxl; // 24

  // 🔹 Radius
  static const double radiusDefault = lg; // 16
  static const double radiusCompact = md; // 12

  // 🔹 Heights
  static const double buttonHeight = 56;
  static const double inputHeight = 56;
  static const double chipHeight = 42;
}
