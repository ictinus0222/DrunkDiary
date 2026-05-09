class AnalyticsParams {
  // Common
  static const userId = 'user_id';
  static const timestamp = 'timestamp';
  static const screenName = 'screen_name';
  static const previousScreen = 'previous_screen';
  static const platform = 'platform';
  static const appVersion = 'app_version';

  // Auth/Onboarding
  static const method = 'method'; // email, google, etc
  static const stepIndex = 'step_index';
  static const stepName = 'step_name';
  static const errorCode = 'error_code';

  // Drink Logging
  static const drinkType = 'drink_type';
  static const hasPhoto = 'has_photo';
  static const ratingValue = 'rating_value';
  static const logKind = 'log_kind'; // log, review, retro

  // Search/Discovery
  static const searchTerm = 'search_term';
  static const searchCategory = 'search_category';
  static const resultCount = 'result_count';
  static const alcoholId = 'alcohol_id';

  // Session
  static const sessionDurationSeconds = 'session_duration_seconds';
  static const screensPerSession = 'screens_per_session';
  static const logsPerSession = 'logs_per_session';

  // Performance
  static const durationMs = 'duration_ms';
  static const operationName = 'operation_name';
  static const status = 'status'; // success, failure

  // Friction
  static const widgetId = 'widget_id';
  static const tapCount = 'tap_count';
}
