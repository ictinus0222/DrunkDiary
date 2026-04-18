import 'package:flutter/material.dart';
import '../../../app/app_theme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

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
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick setup • Step $currentStep of $totalSteps',
          style: AppTextStyles.caption.copyWith(
            color: customColors.textMuted,
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
                      ? Theme.of(context).colorScheme.primary
                      : customColors.borderDark.withValues(alpha: 0.5),
                ),
                child: isCurrent
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
                                color: Theme.of(context).colorScheme.primary,
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

class OnboardingChoiceCard extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const OnboardingChoiceCard({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<OnboardingChoiceCard> createState() => _OnboardingChoiceCardState();
}

class _OnboardingChoiceCardState extends State<OnboardingChoiceCard>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
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
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 64,
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: widget.isSelected
                ? primaryColor.withValues(alpha: 0.1)
                : customColors.cardBackground,
            border: Border.all(
              color: widget.isSelected
                  ? primaryColor
                  : customColors.borderDark,
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w500,
                    color: widget.isSelected ? Colors.white : Colors.white70,
                  ),
                ),
              ),
              if (widget.isSelected)
                Icon(Icons.check_circle, color: primaryColor, size: 20),
            ],
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
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // Absolute black for premium feel
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              progress,
              const SizedBox(height: AppSpacing.hero),
              Text(
                title,
                style: AppTextStyles.section.copyWith(
                  fontSize: 28,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle,
                style: AppTextStyles.body.copyWith(
                  color: customColors.textMuted,
                  height: 1.5,
                ),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: AppSpacing.hero),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: body,
                ),
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

    return GestureDetector(
      onTapDown: widget.isEnabled && !widget.isLoading 
          ? (_) => _controller.forward() 
          : null,
      onTapUp: widget.isEnabled && !widget.isLoading 
          ? (_) => _controller.reverse() 
          : null,
      onTapCancel: widget.isEnabled && !widget.isLoading 
          ? () => _controller.reverse() 
          : null,
      onTap: widget.isEnabled && !widget.isLoading ? widget.onPressed : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.isEnabled 
                ? primaryColor 
                : Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Saving...',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : Text(
                  widget.label,
                  style: AppTextStyles.body.copyWith(
                    color: widget.isEnabled ? Colors.black : Colors.white38,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
