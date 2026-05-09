import 'package:flutter/foundation.dart';

enum AnalyticsEnvironment {
  development,
  staging,
  production,
}

class AnalyticsConfig {
  static AnalyticsEnvironment get current {
    if (kReleaseMode) {
      return AnalyticsEnvironment.production;
    } else if (kProfileMode) {
      return AnalyticsEnvironment.staging;
    } else {
      return AnalyticsEnvironment.development;
    }
  }

  static bool get isTrackingEnabled {
    // Disable tracking in development to prevent data pollution
    return current != AnalyticsEnvironment.development;
  }

  static bool get shouldLogToConsole {
    // Enable console logging in dev/staging for verification
    return current != AnalyticsEnvironment.production;
  }
}
