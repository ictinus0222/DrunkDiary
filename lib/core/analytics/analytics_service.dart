import 'dart:developer' as dev;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'analytics_environment.dart';
import 'analytics_event_names.dart';
import 'analytics_parameters.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  // Track simple events with environment guard
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (!AnalyticsConfig.isTrackingEnabled) {
      if (AnalyticsConfig.shouldLogToConsole) {
        dev.log('📊 [DEBUG ANALYTICS] Event: $name, Params: $parameters', name: 'Analytics');
      }
      return;
    }

    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e, stack) {
      dev.log('❌ Failed to log event $name', error: e, stackTrace: stack);
    }
  }

  // Identity
  Future<void> setUserId(String userId) async {
    if (AnalyticsConfig.isTrackingEnabled) {
      await _analytics.setUserId(id: userId);
    }
    await _crashlytics.setUserIdentifier(userId);
  }

  Future<void> setUserProperty(String name, String value) async {
    if (AnalyticsConfig.isTrackingEnabled) {
      await _analytics.setUserProperty(name: name, value: value);
    }
    await _crashlytics.setCustomKey(name, value);
  }

  // Failure Tracking (Crashlytics + Analytics)
  Future<void> logFailure({
    required String operation,
    required dynamic error,
    StackTrace? stackTrace,
    Map<String, Object>? extraParams,
  }) async {
    final params = {
      AnalyticsParams.operationName: operation,
      AnalyticsParams.errorCode: error.toString(),
      ...?extraParams,
    };

    await logEvent(name: AnalyticsEvents.repositoryOperation, parameters: {
      ...params,
      AnalyticsParams.status: 'failure',
    });

    if (AnalyticsConfig.isTrackingEnabled) {
      await _crashlytics.recordError(error, stackTrace, reason: operation, fatal: false);
    }
  }

  // Breadcrumbs for Crashlytics
  void addBreadcrumb(String message) {
    _crashlytics.log(message);
    if (AnalyticsConfig.shouldLogToConsole) {
      dev.log('🍞 [BREADCRUMB] $message', name: 'Analytics');
    }
  }

  // --- Legacy Compatibility & Helper Methods ---

  Future<void> logLogin(String method) async {
    await logEvent(
      name: AnalyticsEvents.loginCompleted,
      parameters: {AnalyticsParams.method: method},
    );
  }

  Future<void> logSignUp(String method) async {
    await logEvent(
      name: AnalyticsEvents.signupCompleted,
      parameters: {AnalyticsParams.method: method},
    );
  }

  Future<void> logOnboardingComplete() async {
    await logEvent(name: AnalyticsEvents.onboardingCompleted);
  }

  Future<void> logCreateDrinkLog({
    String? logKind,
    String? alcoholType,
    String? reaction,
    double? rating,
    bool? hasPhoto,
  }) async {
    await logEvent(
      name: AnalyticsEvents.drinkLogged,
      parameters: {
        if (logKind != null) 'log_kind': logKind,
        if (alcoholType != null) AnalyticsParams.drinkType: alcoholType,
        if (reaction != null) 'reaction': reaction,
        if (rating != null) AnalyticsParams.ratingValue: rating,
        if (hasPhoto != null) AnalyticsParams.hasPhoto: hasPhoto,
      },
    );
  }

  Future<void> logAddToWishlist({
    required String alcoholId,
    required String alcoholName,
  }) async {
    await logEvent(
      name: AnalyticsEvents.repositoryOperation,
      parameters: {
        AnalyticsParams.operationName: 'add_to_wishlist',
        'alcohol_id': alcoholId,
        'alcohol_name': alcoholName,
      },
    );
  }
}
