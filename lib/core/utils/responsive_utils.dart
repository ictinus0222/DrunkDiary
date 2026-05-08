import 'package:flutter/material.dart';
import '../theme/responsive_tokens.dart';

/// 🛠️ Responsive extensions and helpers.
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  bool get isMobile => screenWidth < AppBreakpoints.mobile;
  bool get isTablet => screenWidth >= AppBreakpoints.mobile && screenWidth < AppBreakpoints.tablet;
  bool get isDesktop => screenWidth >= AppBreakpoints.tablet;

  /// Returns a value based on the current platform width.
  T responsiveValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }

  /// Semantic responsive tokens.
  LayoutDensity get currentDensity => LayoutDensity.fromWidth(screenWidth);
  
  double get pagePadding => responsiveValue(mobile: 16, tablet: 24, desktop: 32);
  
  double get feedMaxWidth => AppWidths.feed;
  double get formMaxWidth => AppWidths.form;
}

/// 👁️ Helper to conditionally show/hide content based on platform.
class ResponsiveVisibility extends StatelessWidget {
  final bool mobile;
  final bool tablet;
  final bool desktop;
  final Widget child;

  const ResponsiveVisibility({
    super.key,
    this.mobile = true,
    this.tablet = true,
    this.desktop = true,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final show = context.responsiveValue(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );

    return show ? child : const SizedBox.shrink();
  }
}
