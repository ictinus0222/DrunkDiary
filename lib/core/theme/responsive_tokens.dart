import 'package:flutter/material.dart';

/// 📱 System-standard breakpoints for DrunkDiary.
class AppBreakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
  // Desktop is > 1024
}

/// 📏 Semantic content width constraints.
/// Prevents UI from feeling "blown out" on larger screens.
class AppWidths {
  static const double feed = 720;
  static const double form = 580;
  static const double profile = 850;
  static const double grid = 1200;
  
  static const double modal = 500;
  static const double bottomSheet = 640;
  static const double dialog = 480;
}

/// 📐 Adaptive corner radii tokens.
class AppRadius {
  static const double cardMobile = 16;
  static const double cardTablet = 24;
  
  static const double modalMobile = 24;
  static const double modalTablet = 32;
}

/// ⚡ Layout Density system.
/// Influences spacing, padding, and information density globally.
enum LayoutDensity {
  /// Denser grids, smaller gaps, higher information density (Desktop).
  compact,
  
  /// Standard balanced layout (Tablet).
  comfortable,
  
  /// More breathing room, larger touch targets (Mobile).
  expanded;

  static LayoutDensity fromWidth(double width) {
    if (width >= AppBreakpoints.tablet) return LayoutDensity.compact;
    if (width >= AppBreakpoints.mobile) return LayoutDensity.comfortable;
    return LayoutDensity.expanded;
  }
}
