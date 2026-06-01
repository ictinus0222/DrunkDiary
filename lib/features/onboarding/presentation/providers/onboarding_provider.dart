import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/onboarding_step_config.dart';
import '../constants/onboarding_copy.dart';
import '../../../../core/constants/reaction_config.dart';
import '../../../drink_logs/models/drink_model_dto.dart';

enum FirstLogStatus {
  none,
  draft,
  ready,
  uploading,
  completed,
}

class OnboardingState {
  final int currentStepIndex;
  final List<OnboardingStepConfig> steps;
  final bool isLegalAge;
  final String username;
  final Set<String> preferredDrinkCategories;
  final bool initialPrivacyPreference;
  final bool isLoading;

  // First log onboarding draft state
  final FirstLogStatus firstLogStatus;
  final String? firstLogPhotoPath;
  final String? firstLogAlcoholName;
  final String? firstLogAlcoholId;
  final String? firstLogAlcoholType;
  final bool? firstLogIsCustom;
  final DrinkReaction? firstLogReaction;
  final double? firstLogRating;
  final LogKind? firstLogKind;
  final String? firstLogNote;

  OnboardingState({
    this.currentStepIndex = 0,
    required this.steps,
    this.isLegalAge = false,
    this.username = '',
    this.preferredDrinkCategories = const {},
    this.initialPrivacyPreference = false,
    this.isLoading = false,
    this.firstLogStatus = FirstLogStatus.none,
    this.firstLogPhotoPath,
    this.firstLogAlcoholName,
    this.firstLogAlcoholId,
    this.firstLogAlcoholType,
    this.firstLogIsCustom,
    this.firstLogReaction,
    this.firstLogRating,
    this.firstLogKind,
    this.firstLogNote,
  });

  OnboardingState copyWith({
    int? currentStepIndex,
    List<OnboardingStepConfig>? steps,
    bool? isLegalAge,
    String? username,
    Set<String>? preferredDrinkCategories,
    bool? initialPrivacyPreference,
    bool? isLoading,
    FirstLogStatus? firstLogStatus,
    String? firstLogPhotoPath,
    String? firstLogAlcoholName,
    String? firstLogAlcoholId,
    String? firstLogAlcoholType,
    bool? firstLogIsCustom,
    DrinkReaction? firstLogReaction,
    double? firstLogRating,
    LogKind? firstLogKind,
    String? firstLogNote,
    bool clearFirstLogFields = false,
  }) {
    return OnboardingState(
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      steps: steps ?? this.steps,
      isLegalAge: isLegalAge ?? this.isLegalAge,
      username: username ?? this.username,
      preferredDrinkCategories: preferredDrinkCategories ?? this.preferredDrinkCategories,
      initialPrivacyPreference: initialPrivacyPreference ?? this.initialPrivacyPreference,
      isLoading: isLoading ?? this.isLoading,
      firstLogStatus: firstLogStatus ?? (clearFirstLogFields ? FirstLogStatus.none : this.firstLogStatus),
      firstLogPhotoPath: firstLogPhotoPath ?? (clearFirstLogFields ? null : this.firstLogPhotoPath),
      firstLogAlcoholName: firstLogAlcoholName ?? (clearFirstLogFields ? null : this.firstLogAlcoholName),
      firstLogAlcoholId: firstLogAlcoholId ?? (clearFirstLogFields ? null : this.firstLogAlcoholId),
      firstLogAlcoholType: firstLogAlcoholType ?? (clearFirstLogFields ? null : this.firstLogAlcoholType),
      firstLogIsCustom: firstLogIsCustom ?? (clearFirstLogFields ? null : this.firstLogIsCustom),
      firstLogReaction: firstLogReaction ?? (clearFirstLogFields ? null : this.firstLogReaction),
      firstLogRating: firstLogRating ?? (clearFirstLogFields ? null : this.firstLogRating),
      firstLogKind: firstLogKind ?? (clearFirstLogFields ? null : this.firstLogKind),
      firstLogNote: firstLogNote ?? (clearFirstLogFields ? null : this.firstLogNote),
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

  Future<void> saveFirstLogDraft({required String photoPath}) async {
    final oldPath = state.firstLogPhotoPath;
    if (oldPath != null && oldPath != photoPath) {
      try {
        final oldFile = File(oldPath);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      } catch (e) {
        debugPrint('Error deleting old first log draft photo: $e');
      }
    }
    state = state.copyWith(
      firstLogPhotoPath: photoPath,
      firstLogStatus: FirstLogStatus.draft,
      clearFirstLogFields: true,
    );
  }

  void updateFirstLogDetails({
    String? alcoholName,
    String? alcoholId,
    String? alcoholType,
    bool? isCustom,
    DrinkReaction? reaction,
    double? rating,
    LogKind? logKind,
    String? note,
  }) {
    state = state.copyWith(
      firstLogAlcoholName: alcoholName,
      firstLogAlcoholId: alcoholId,
      firstLogAlcoholType: alcoholType,
      firstLogIsCustom: isCustom,
      firstLogReaction: reaction,
      firstLogRating: rating,
      firstLogKind: logKind,
      firstLogNote: note,
      firstLogStatus: FirstLogStatus.ready,
    );
  }

  void setFirstLogStatus(FirstLogStatus status) {
    state = state.copyWith(firstLogStatus: status);
  }

  Future<void> clearFirstLog() async {
    final photoPath = state.firstLogPhotoPath;
    if (photoPath != null) {
      try {
        final file = File(photoPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error deleting first log draft photo on clear: $e');
      }
    }
    state = state.copyWith(clearFirstLogFields: true);
  }
}
