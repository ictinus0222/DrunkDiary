import 'package:flutter/material.dart';
import 'analytics_service.dart';
import 'session_tracker.dart';
import 'analytics_parameters.dart';

class ScreenTrackingObserver extends RouteObserver<PageRoute<dynamic>> {
  final AnalyticsService _analytics;
  final SessionTracker _sessionTracker;

  ScreenTrackingObserver(this._analytics, this._sessionTracker);

  void _sendScreenView(String? screenName, String? previousName) {
    if (screenName == null) return;

    _analytics.logEvent(
      name: 'screen_view',
      parameters: {
        AnalyticsParams.screenName: screenName,
        if (previousName != null) AnalyticsParams.previousScreen: previousName,
      },
    );
    _analytics.addBreadcrumb('Navigated to: $screenName');
    _sessionTracker.incrementScreens();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) {
      _sendScreenView(
        route.settings.name,
        previousRoute?.settings.name,
      );
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute is PageRoute) {
      _sendScreenView(
        newRoute.settings.name,
        oldRoute?.settings.name,
      );
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute is PageRoute) {
      _sendScreenView(
        previousRoute.settings.name,
        route.settings.name,
      );
    }
  }
}
