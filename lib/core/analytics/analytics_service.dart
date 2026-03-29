import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Identity Tracking
  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }

  Future<void> setUserProperty(String name, String value) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  // Track standard Login
  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  // Track standard SignUp
  Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  // Track Onboarding completion
  Future<void> logOnboardingComplete() async {
    await _analytics.logEvent(
      name: 'onboarding_complete',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track individual onboarding steps
  Future<void> logOnboardingStep(int stepIndex, String stepName) async {
    await _analytics.logEvent(
      name: 'onboarding_step',
      parameters: {
        'step_index': stepIndex,
        'step_name': stepName,
      },
    );
  }

  // Track Drink Log / Review creation
  Future<void> logCreateDrinkLog({
    required String logKind, // 'log' or 'review'
    required String alcoholType,
    required String reaction, // 'loved', 'liked', 'nah' or rating
  }) async {
    await _analytics.logEvent(
      name: 'create_drink_log',
      parameters: {
        'log_kind': logKind,
        'alcohol_type': alcoholType,
        'reaction': reaction,
      },
    );
  }

  // Track Search queries
  Future<void> logSearch(String searchTerm) async {
    await _analytics.logSearch(searchTerm: searchTerm);
  }
 
  // Track Search Health (Zero Results)
  Future<void> logZeroResults(String searchTerm) async {
    await _analytics.logEvent(
      name: 'zero_search_results',
      parameters: {
        'search_term': searchTerm,
      },
    );
  }
 
  // Track Wishlist Intent
  Future<void> logAddToWishlist({
    required String alcoholId,
    required String alcoholName,
  }) async {
    await _analytics.logEvent(
      name: 'add_to_wishlist',
      parameters: {
        'item_id': alcoholId,
        'item_name': alcoholName,
      },
    );
  }
}
