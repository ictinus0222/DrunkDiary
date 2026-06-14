import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

/// 🏛️ The layout governance layer for DrunkDiary.
/// Ensures all screens follow the same constraint and centering rules.
class ResponsiveScaffoldBody extends StatelessWidget {
  final Widget child;
  final bool constrained;
  final double? maxWidth;
  final EdgeInsets? padding;

  const ResponsiveScaffoldBody({
    super.key,
    required this.child,
    this.constrained = true,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (!constrained) return child;

    return Center(
      child: ResponsiveConstrainedBox(
        maxWidth: maxWidth,
        padding: padding,
        child: child,
      ),
    );
  }
}

/// 📦 A centered box that enforces semantic width constraints.
class ResponsiveConstrainedBox extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;

  const ResponsiveConstrainedBox({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = maxWidth ?? context.feedMaxWidth;
    final effectivePadding = padding ?? EdgeInsets.symmetric(horizontal: context.pagePadding);

    return Container(
      constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
      padding: effectivePadding,
      child: child,
    );
  }
}

/// 🎞️ A sliver version of ResponsiveConstrainedBox.
/// Used inside CustomScrollView to constrain sliver children.
class SliverResponsiveConstrainedBox extends StatelessWidget {
  final Widget sliver;
  final double? maxWidth;
  final EdgeInsets? padding;

  const SliverResponsiveConstrainedBox({
    super.key,
    required this.sliver,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = maxWidth ?? context.feedMaxWidth;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = (screenWidth > effectiveMaxWidth)
        ? (screenWidth - effectiveMaxWidth) / 2
        : 0.0;

    final basePadding = padding ?? EdgeInsets.symmetric(horizontal: context.pagePadding);

    return SliverPadding(
      padding: basePadding.copyWith(
        left: basePadding.left + horizontalPadding,
        right: basePadding.right + horizontalPadding,
      ),
      sliver: sliver,
    );
  }
}
