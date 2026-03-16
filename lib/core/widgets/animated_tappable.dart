import 'package:flutter/material.dart';

/// A widget that provides a subtle scale-down effect when tapped.
/// This makes the UI feel tactile and premium.
class AnimatedTappable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleOnTap;

  const AnimatedTappable({
    super.key,
    required this.child,
    this.onTap,
    this.scaleOnTap = 0.97,
  });

  @override
  State<AnimatedTappable> createState() => _AnimatedTappableState();
}

class _AnimatedTappableState extends State<AnimatedTappable>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleOnTap,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {}

  void _handleTapUp(TapUpDetails details) {}

  void _handleTapCancel() {}

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
