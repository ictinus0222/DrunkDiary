import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/onboarding_provider.dart';
import 'age_check_step.dart';

class PrivacyStep extends ConsumerWidget {
  final VoidCallback onNext;

  const PrivacyStep({
    super.key,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    
    return Column(
      children: [
        OnboardingChoiceCard(
          label: 'Public (Share with community)',
          isSelected: !state.initialPrivacyPreference,
          onTap: () {
            ref.read(onboardingProvider.notifier).setPrivacyPreference(false);
            onNext();
          },
        ),
        OnboardingChoiceCard(
          label: 'Private (Friends only)',
          isSelected: state.initialPrivacyPreference,
          onTap: () {
            ref.read(onboardingProvider.notifier).setPrivacyPreference(true);
            onNext();
          },
        ),
      ],
    );
  }
}
