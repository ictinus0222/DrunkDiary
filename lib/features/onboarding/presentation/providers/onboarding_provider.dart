import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/onboarding_step_config.dart';
import '../constants/onboarding_copy.dart';

class OnboardingState {
  final int currentStepIndex;
  final List<OnboardingStepConfig> steps;
  final bool isLegalAge;
  final String username;
  final Set<String> preferredDrinkCategories;
  final bool initialPrivacyPreference;
  final bool isLoading;

  OnboardingState({
    this.currentStepIndex = 0,
    required this.steps,
    this.isLegalAge = false,
    this.username = '',
    this.preferredDrinkCategories = const {},
    this.initialPrivacyPreference = false,
    this.isLoading = false,
  });

  OnboardingState copyWith({
    int? currentStepIndex,
    List<OnboardingStepConfig>? steps,
    bool? isLegalAge,
    String? username,
    Set<String>? preferredDrinkCategories,
    bool? initialPrivacyPreference,
    bool? isLoading,
  }) {
    return OnboardingState(
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      steps: steps ?? this.steps,
      isLegalAge: isLegalAge ?? this.isLegalAge,
      username: username ?? this.username,
      preferredDrinkCategories: preferredDrinkCategories ?? this.preferredDrinkCategories,
      initialPrivacyPreference: initialPrivacyPreference ?? this.initialPrivacyPreference,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final onboardingProvider = NotifierProvider<OnboardingNotifier, OnboardingState>(() {
  return OnboardingNotifier();
});

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => OnboardingState(steps: _defaultSteps);

  static final List<OnboardingStepConfig> _defaultSteps = [
    const OnboardingStepConfig(
      id: 'identity',
      headline: OnboardingCopy.screen1Headline,
      subtext: OnboardingCopy.screen1Subtext,
      analyticsName: 'education_diary',
      type: OnboardingStepType.educational,
    ),
    const OnboardingStepConfig(
      id: 'log_anything',
      headline: OnboardingCopy.screen2Headline,
      subtext: OnboardingCopy.screen2Subtext,
      analyticsName: 'education_logging',
      type: OnboardingStepType.educational,
    ),
    const OnboardingStepConfig(
      id: 'build_shelf',
      headline: OnboardingCopy.screen3Headline,
      subtext: OnboardingCopy.screen3Subtext,
      analyticsName: 'education_shelf',
      type: OnboardingStepType.educational,
    ),
    const OnboardingStepConfig(
      id: 'social',
      headline: OnboardingCopy.screen4Headline,
      subtext: OnboardingCopy.screen4Subtext,
      analyticsName: 'education_social',
      type: OnboardingStepType.educational,
    ),
    const OnboardingStepConfig(
      id: 'privacy',
      headline: OnboardingCopy.screen5Headline,
      subtext: OnboardingCopy.screen5Subtext,
      analyticsName: 'education_privacy',
      type: OnboardingStepType.setup,
    ),
    const OnboardingStepConfig(
      id: 'setup_age',
      headline: OnboardingCopy.setupAgeTitle,
      subtext: OnboardingCopy.setupAgeSubtitle,
      analyticsName: 'setup_age',
      type: OnboardingStepType.setup,
    ),
    const OnboardingStepConfig(
      id: 'setup_username',
      headline: OnboardingCopy.setupUsernameTitle,
      subtext: OnboardingCopy.setupUsernameSubtitle,
      analyticsName: 'setup_username',
      type: OnboardingStepType.setup,
    ),
    const OnboardingStepConfig(
      id: 'setup_preferences',
      headline: OnboardingCopy.setupPreferencesTitle,
      subtext: OnboardingCopy.setupPreferencesSubtitle,
      analyticsName: 'setup_preferences',
      type: OnboardingStepType.setup,
    ),
    const OnboardingStepConfig(
      id: 'final_cta',
      headline: OnboardingCopy.screen6Headline,
      subtext: OnboardingCopy.screen6Subtext,
      analyticsName: 'final_cta',
      type: OnboardingStepType.finalCta,
    ),
  ];

  void nextStep() {
    if (state.currentStepIndex < state.steps.length - 1) {
      state = state.copyWith(currentStepIndex: state.currentStepIndex + 1);
    }
  }

  void previousStep() {
    if (state.currentStepIndex > 0) {
      state = state.copyWith(currentStepIndex: state.currentStepIndex - 1);
    }
  }

  void setLegalAge(bool value) {
    state = state.copyWith(isLegalAge: value);
  }

  void setUsername(String value) {
    state = state.copyWith(username: value);
  }

  void togglePreference(String category) {
    final newPrefs = Set<String>.from(state.preferredDrinkCategories);
    if (newPrefs.contains(category)) {
      newPrefs.remove(category);
    } else {
      newPrefs.add(category);
    }
    state = state.copyWith(preferredDrinkCategories: newPrefs);
  }

  void setPrivacyPreference(bool value) {
    state = state.copyWith(initialPrivacyPreference: value);
  }

  void setLoading(bool value) {
    state = state.copyWith(isLoading: value);
  }
}
