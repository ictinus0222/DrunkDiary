import 'package:flutter_riverpod/flutter_riverpod.dart';

class PostOnboardingState {
  final bool shouldShowFirstLogGuidance;
  final bool hasTriggered;

  PostOnboardingState({
    this.shouldShowFirstLogGuidance = false,
    this.hasTriggered = false,
  });

  PostOnboardingState copyWith({
    bool? shouldShowFirstLogGuidance,
    bool? hasTriggered,
  }) {
    return PostOnboardingState(
      shouldShowFirstLogGuidance: shouldShowFirstLogGuidance ?? this.shouldShowFirstLogGuidance,
      hasTriggered: hasTriggered ?? this.hasTriggered,
    );
  }
}

final postOnboardingHandlerProvider = NotifierProvider<PostOnboardingNotifier, PostOnboardingState>(() {
  return PostOnboardingNotifier();
});

class PostOnboardingNotifier extends Notifier<PostOnboardingState> {
  @override
  PostOnboardingState build() => PostOnboardingState();

  void setShouldShowFirstLogGuidance(bool value) {
    state = state.copyWith(shouldShowFirstLogGuidance: value);
  }

  void markAsTriggered() {
    state = state.copyWith(hasTriggered: true, shouldShowFirstLogGuidance: false);
  }
}
