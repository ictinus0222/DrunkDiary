import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/onboarding_provider.dart';
import 'age_check_step.dart';

class PreferencesStep extends ConsumerWidget {
  const PreferencesStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final options = [
      'Beer 🍺',
      'Whisky 🥃',
      'Cocktails 🍸',
      'Wine 🍷',
      'Vodka / Gin / Rum 🍸',
      'I’m still exploring 🔎',
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: options.map((option) {
          final isSelected = state.preferredDrinkCategories.contains(option);
          return OnboardingChoiceCard(
            label: option,
            isSelected: isSelected,
            onTap: () {
              ref.read(onboardingProvider.notifier).togglePreference(option);
              HapticFeedback.selectionClick();
            },
          );
        }).toList(),
      ),
    );
  }
}
