import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:drunk_diary/core/utils/screenshot_provider.dart';
import 'package:drunk_diary/app/app_routes.dart';
import 'package:drunk_diary/features/activity/screens/diary_screen.dart';
import 'package:drunk_diary/features/drink_logs/screens/shelf_screen.dart';
import 'package:drunk_diary/features/home/screens/home_screen.dart';
import 'package:drunk_diary/features/auth/screens/login_screen.dart';
import 'package:drunk_diary/features/onboarding/presentation/screens/onboarding_flow_screen.dart';
import 'package:drunk_diary/app/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/auth/auth_gate.dart';
import 'core/firebase/firebase_options.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/search/screens/search_screen.dart';
import 'features/admin/screens/admin_settings_screen.dart';
import 'features/admin/screens/admin_bottle_manager_screen.dart';
import 'features/activity/screens/notifications_screen.dart';
import 'features/profile/screens/settings_screen.dart';
import 'splash/splash_screen.dart';
 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'core/analytics/analytics_service.dart';
import 'core/analytics/session_tracker.dart';
import 'core/analytics/screen_tracking_observer.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Initialize Google Sign-In
  await GoogleSignIn.instance.initialize(
    serverClientId: '1080840005468-j82oa5apllnb65o6r4j831crdplodv3t.apps.googleusercontent.com',
  );

  runApp(
    const ProviderScope(
      child: DrunkDiaryApp(),
    ),
  );
}

class DrunkDiaryApp extends ConsumerStatefulWidget {
  const DrunkDiaryApp({super.key});

  @override
  ConsumerState<DrunkDiaryApp> createState() => _DrunkDiaryAppState();
}

class _DrunkDiaryAppState extends ConsumerState<DrunkDiaryApp> with WidgetsBindingObserver {
  late ScreenTrackingObserver _observer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    final analytics = ref.read(analyticsServiceProvider);
    final sessionTracker = ref.read(sessionTrackerProvider);
    
    _observer = ScreenTrackingObserver(analytics, sessionTracker);
    
    // Start initial session
    sessionTracker.startSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final sessionTracker = ref.read(sessionTrackerProvider);
    if (state == AppLifecycleState.paused) {
      sessionTracker.endSession();
    } else if (state == AppLifecycleState.resumed) {
      sessionTracker.startSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DrunkDiary',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.darkTheme,
      navigatorObservers: [_observer],
      home: const AuthGate(),
      builder: (context, child) {
        return Screenshot(
          controller: ref.read(screenshotControllerProvider),
          child: child!,
        );
      },
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.home: (context) => const HomeScreen(),
        AppRoutes.onboarding: (context) => const OnboardingFlowScreen(),
        AppRoutes.diary: (context) => const DiaryScreen(),
        AppRoutes.profile: (context) => const ProfileScreen(),
        AppRoutes.shelf: (context) => const ShelfScreen(),
        AppRoutes.search: (context) => const SearchScreen(),
        AppRoutes.notifications: (context) => const NotificationsScreen(),
        AppRoutes.adminSettings: (context) => const AdminSettingsScreen(),
        AppRoutes.adminBottleManager: (context) => const AdminBottleManagerScreen(),
        AppRoutes.settings: (context) => const SettingsScreen(),
      },
    );
  }
}
