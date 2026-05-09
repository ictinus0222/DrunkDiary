import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'analytics_service.dart';
import 'analytics_event_names.dart';
import 'analytics_parameters.dart';

final frictionTrackerProvider = Provider<FrictionTracker>((ref) {
  final analytics = ref.watch(analyticsServiceProvider);
  return FrictionTracker(analytics);
});

class FrictionTracker {
  final AnalyticsService _analytics;
  
  // Rage Tap Detection
  int _tapCount = 0;
  String? _lastWidgetId;
  Timer? _tapTimer;

  // Rapid Back Detection
  DateTime? _lastBackPress;

  FrictionTracker(this._analytics);

  void logTap(String widgetId) {
    if (_lastWidgetId == widgetId) {
      _tapCount++;
      if (_tapCount >= 5) {
        _analytics.logEvent(
          name: AnalyticsEvents.rageTapDetected,
          parameters: {
            AnalyticsParams.widgetId: widgetId,
            AnalyticsParams.tapCount: _tapCount,
          },
        );
        _tapCount = 0; // Reset after logging
      }
    } else {
      _tapCount = 1;
      _lastWidgetId = widgetId;
    }

    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(seconds: 1), () {
      _tapCount = 0;
      _lastWidgetId = null;
    });
  }

  void logBackPress() {
    final now = DateTime.now();
    if (_lastBackPress != null) {
      final diff = now.difference(_lastBackPress!);
      if (diff.inMilliseconds < 500) {
        _analytics.logEvent(name: AnalyticsEvents.rapidBackPress);
      }
    }
    _lastBackPress = now;
  }

  void logSearchAbandoned(String term) {
    _analytics.logEvent(
      name: AnalyticsEvents.searchAbandoned,
      parameters: {AnalyticsParams.searchTerm: term},
    );
  }
}
