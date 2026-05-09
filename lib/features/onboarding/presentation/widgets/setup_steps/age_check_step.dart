import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../onboarding_components.dart';
import '../../providers/onboarding_provider.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

class AgeCheckStep extends ConsumerWidget {
  final VoidCallback onNext;
  final VoidCallback onBlock;

  const AgeCheckStep({
    super.key,
    required this.onNext,
    required this.onBlock,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    
    return Column(
      children: [
        OnboardingChoiceCard(
          label: 'Yes, I am of legal age',
          isSelected: state.isLegalAge,
          onTap: () {
            ref.read(onboardingProvider.notifier).setLegalAge(true);
            HapticFeedback.lightImpact();
            onNext();
          },
        ),
        OnboardingChoiceCard(
          label: 'No, I am not',
          isSelected: false,
          onTap: () {
            HapticFeedback.mediumImpact();
            onBlock();
          },
        ),
      ],
    );
  }
}

class OnboardingChoiceCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 64,
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isSelected ? primaryColor.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.white70,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: primaryColor, size: 20),
          ],
        ),
      ),
    );
  }
}
