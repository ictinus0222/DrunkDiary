import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart' as s;

class AppShimmer extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final Widget? child;

  const AppShimmer({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius,
    this.child,
  });

  const AppShimmer.rectangular({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius,
  }) : child = null;

  const AppShimmer.circular({
    super.key,
    required double size,
    BorderRadius? borderRadius,
  })  : width = size,
        height = size,
        borderRadius = borderRadius ?? const BorderRadius.all(Radius.circular(50)),
        child = null;

  @override
  Widget build(BuildContext context) {
    return s.Shimmer.fromColors(
      baseColor: Colors.grey[850]!,
      highlightColor: Colors.grey[800]!,
      child: child ??
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey[900]!,
              borderRadius: borderRadius ?? BorderRadius.circular(12),
            ),
          ),
    );
  }
}
