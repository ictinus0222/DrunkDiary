import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/responsive_tokens.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/responsive_layout.dart';

class OnboardingProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const OnboardingProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isReducedMotion = MediaQuery.of(context).accessibleNavigation;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step $currentStep of $totalSteps',
          style: AppTextStyles.caption.copyWith(
            color: Colors.white38,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: List.generate(totalSteps, (index) {
            final isCompleted = index < currentStep;
            final isCurrent = index == currentStep - 1;

            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(
                  right: index == totalSteps - 1 ? 0 : 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: isCompleted || isCurrent
                      ? primaryColor
                      : Colors.white10,
                ),
                child: isCurrent && !isReducedMotion
                    ? TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, value, child) {
                          return FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: value,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                color: primaryColor,
                              ),
                            ),
                          );
                        },
                      )
                    : null,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class OnboardingButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final bool isEnabled;
  final VoidCallback? onPressed;

  const OnboardingButton({
    super.key,
    required this.label,
    this.isLoading = false,
    this.isEnabled = true,
    this.onPressed,
  });

  @override
  State<OnboardingButton> createState() => _OnboardingButtonState();
}

class _OnboardingButtonState extends State<OnboardingButton>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isReducedMotion = MediaQuery.of(context).accessibleNavigation;

    return GestureDetector(
      onTapDown: widget.isEnabled && !widget.isLoading && !isReducedMotion
          ? (_) => _controller.forward() 
          : null,
      onTapUp: widget.isEnabled && !widget.isLoading && !isReducedMotion
          ? (_) => _controller.reverse() 
          : null,
      onTapCancel: widget.isEnabled && !widget.isLoading && !isReducedMotion
          ? () => _controller.reverse() 
          : null,
      onTap: widget.isEnabled && !widget.isLoading ? widget.onPressed : null,
      child: ScaleTransition(
        scale: isReducedMotion ? const AlwaysStoppedAnimation(1.0) : _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.isEnabled 
                ? primaryColor 
                : Colors.white10,
            borderRadius: BorderRadius.circular(18),
            boxShadow: widget.isEnabled && !isReducedMotion ? [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ] : null,
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : Text(
                  widget.label,
                  style: AppTextStyles.body.copyWith(
                    color: widget.isEnabled ? Colors.black : Colors.white38,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}

class OnboardingLayout extends StatelessWidget {
  final Widget progress;
  final String title;
  final String subtitle;
  final Widget body;
  final Widget? cta;

  const OnboardingLayout({
    super.key,
    required this.progress,
    required this.title,
    required this.subtitle,
    required this.body,
    this.cta,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: ResponsiveScaffoldBody(
        maxWidth: AppWidths.form,
        padding: EdgeInsets.zero,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60), // Push content down
                progress,
                const SizedBox(height: AppSpacing.hero),
                Text(
                  title,
                  style: AppTextStyles.section.copyWith(
                    fontSize: 28,
                    color: Colors.white,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'GiveYouGlory',
                    fontSize: 22,
                    color: Colors.amber,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.hero),
                Expanded(
                  child: body,
                ),
                if (cta != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  cta!,
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
