import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'analytics_service.dart';
import 'analytics_event_names.dart';
import 'analytics_parameters.dart';

final funnelTrackerProvider = Provider<FunnelTracker>((ref) {
  final analytics = ref.watch(analyticsServiceProvider);
  return FunnelTracker(analytics);
});

class FunnelTracker {
  final AnalyticsService _analytics;
  static const String _onboardingKey = 'last_onboarding_step';

  FunnelTracker(this._analytics);

  // --- Onboarding Funnel ---

  Future<void> logOnboardingStarted() async {
    await _analytics.logEvent(name: AnalyticsEvents.onboardingStarted);
    await _persistStep(0);
  }

  Future<void> logOnboardingStep(int index, String name) async {
    await _analytics.logEvent(
      name: AnalyticsEvents.onboardingStepViewed,
      parameters: {
        AnalyticsParams.stepIndex: index,
        AnalyticsParams.stepName: name,
      },
    );
    await _persistStep(index);
  }

  Future<void> logOnboardingCompleted() async {
    await _analytics.logEvent(name: AnalyticsEvents.onboardingCompleted);
    await _clearStep();
  }

  Future<void> logFirstLogCtaClicked() async {
    await _analytics.logEvent(name: AnalyticsEvents.firstLogCtaClicked);
  }

  Future<void> logOnboardingAbandoned(int lastStep) async {
    await _analytics.logEvent(
      name: AnalyticsEvents.onboardingAbandoned,
      parameters: {AnalyticsParams.stepIndex: lastStep},
    );
  }

  // --- Logging Funnel ---

  Future<void> logDrinkLogStarted({required String source}) async {
    await _analytics.logEvent(
      name: AnalyticsEvents.logDraftStarted,
      parameters: {'source': source},
    );
  }

  Future<void> logDrinkLogSubmitted({
    required String type,
    required bool hasPhoto,
    required double rating,
  }) async {
    await _analytics.logEvent(
      name: AnalyticsEvents.drinkLogged,
      parameters: {
        AnalyticsParams.drinkType: type,
        AnalyticsParams.hasPhoto: hasPhoto,
        AnalyticsParams.ratingValue: rating,
      },
    );
  }

  // --- Persistence ---

  Future<void> _persistStep(int step) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_onboardingKey, step);
  }

  Future<void> _clearStep() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingKey);
  }

  Future<int?> getLastOnboardingStep() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_onboardingKey);
  }
}
