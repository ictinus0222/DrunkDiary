import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'analytics_service.dart';
import 'analytics_event_names.dart';
import 'analytics_parameters.dart';

final sessionTrackerProvider = Provider<SessionTracker>((ref) {
  final analytics = ref.watch(analyticsServiceProvider);
  return SessionTracker(analytics);
});

class SessionTracker {
  final AnalyticsService _analytics;
  
  DateTime? _sessionStartTime;
  int _screensVisited = 0;
  int _logsCreated = 0;

  SessionTracker(this._analytics);

  void startSession() {
    _sessionStartTime = DateTime.now();
    _screensVisited = 1; // Count initial screen
    _logsCreated = 0;
    
    _analytics.logEvent(name: AnalyticsEvents.sessionStarted);
    _analytics.addBreadcrumb("Session started at $_sessionStartTime");
  }

  void endSession() {
    if (_sessionStartTime == null) return;

    final duration = DateTime.now().difference(_sessionStartTime!);
    
    _analytics.logEvent(
      name: AnalyticsEvents.sessionEnded,
      parameters: {
        AnalyticsParams.sessionDurationSeconds: duration.inSeconds,
        AnalyticsParams.screensPerSession: _screensVisited,
        AnalyticsParams.logsPerSession: _logsCreated,
      },
    );

    _analytics.addBreadcrumb("Session ended. Duration: ${duration.inSeconds}s, Screens: $_screensVisited, Logs: $_logsCreated");
    _sessionStartTime = null;
  }

  void incrementScreens() => _screensVisited++;
  void incrementLogs() => _logsCreated++;
}
