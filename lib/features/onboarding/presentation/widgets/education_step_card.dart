import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class EducationStepCard extends StatefulWidget {
  final String headline;
  final String subtext;
  final Widget? visual;
  final VoidCallback onNext;
  final String? ctaLabel;

  const EducationStepCard({
    super.key,
    required this.headline,
    required this.subtext,
    this.visual,
    required this.onNext,
    this.ctaLabel,
  });

  @override
  State<EducationStepCard> createState() => _EducationStepCardState();
}

class _EducationStepCardState extends State<EducationStepCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _headlineFade;
  late Animation<double> _subtextFade;
  late Animation<double> _visualFade;
  late Animation<double> _ctaFade;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    final isReducedMotion = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.reduceMotion;

    if (isReducedMotion) {
      _headlineFade = AlwaysStoppedAnimation(1.0);
      _subtextFade = AlwaysStoppedAnimation(1.0);
      _visualFade = AlwaysStoppedAnimation(1.0);
      _ctaFade = AlwaysStoppedAnimation(1.0);
      _controller.value = 1.0;
    } else {
      _visualFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
      );
      _headlineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.6, curve: Curves.easeOut)),
      );
      _subtextFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.8, curve: Curves.easeOut)),
      );
      _ctaFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0, curve: Curves.easeOut)),
      );
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: 60), // Push content down
          Expanded(
            child: FadeTransition(
              opacity: _visualFade,
              child: widget.visual ?? const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: AppSpacing.hero),
          FadeTransition(
            opacity: _headlineFade,
            child: Text(
              widget.headline,
              style: AppTextStyles.section.copyWith(
                fontSize: 42,
                color: Colors.white,
                height: 1.1,
                letterSpacing: -1.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FadeTransition(
            opacity: _subtextFade,
            child: Text(
              widget.subtext,
              style: const TextStyle(
                fontFamily: 'GiveYouGlory',
                fontSize: 24,
                color: Colors.amber,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.hero),
          FadeTransition(
            opacity: _ctaFade,
            child: ElevatedButton(
              onPressed: widget.onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                widget.ctaLabel ?? 'Continue',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );

    return content;
  }
}
