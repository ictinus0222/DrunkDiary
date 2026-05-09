class AnalyticsEvents {
  // Auth Funnel
  static const signupStarted = 'signup_started';
  static const signupCompleted = 'signup_completed';
  static const loginCompleted = 'login_completed';
  static const authFailed = 'auth_failed';

  // Onboarding Funnel
  static const onboardingStarted = 'onboarding_started';
  static const onboardingStepViewed = 'onboarding_step_viewed';
  static const onboardingCompleted = 'onboarding_completed';
  static const onboardingSkipped = 'onboarding_skipped';
  static const onboardingAbandoned = 'onboarding_abandoned';

  // Drink Logging Funnel
  static const drinkLogged = 'drink_logged';
  static const logDraftStarted = 'log_draft_started';
  static const logDraftAbandoned = 'log_draft_abandoned';
  static const retroLogCreated = 'retro_log_created';
  static const customDrinkCreated = 'custom_drink_created';
  static const drinkPhotoUploaded = 'drink_photo_uploaded';
  static const ratingAdded = 'rating_added';

  // Discovery & Search
  static const searchUsed = 'search_used';
  static const searchZeroResults = 'search_zero_results';
  static const searchAbandoned = 'search_abandoned';
  static const searchRepeated = 'search_repeated';
  static const alcoholPageOpened = 'alcohol_page_opened';
  static const bottleSearched = 'bottle_searched';
  static const discoveryConversion = 'discovery_conversion'; // View -> Log

  // Social Funnel
  static const profileVisited = 'profile_visited';
  static const friendRequestSent = 'friend_request_sent';
  static const friendRequestAccepted = 'friend_request_accepted';
  static const activityShared = 'activity_shared';
  static const commentAdded = 'comment_added';
  static const likeAdded = 'like_added';
  static const feedEmptySeen = 'feed_empty_seen';

  // Session & Retention
  static const sessionStarted = 'session_started';
  static const sessionEnded = 'session_ended';
  static const returningUserDetected = 'returning_user_detected';

  // UX Friction & Pain
  static const rageTapDetected = 'rage_tap_detected';
  static const rapidBackPress = 'rapid_back_press';
  static const photoUploadFailed = 'photo_upload_failed';
  static const slowScreenRender = 'slow_screen_render';
  static const imageLoadFailed = 'image_load_failed';

  // Performance
  static const repositoryOperation = 'repository_operation';
  static const apiRequestFailed = 'api_request_failed';
}
