import 'package:drunk_diary/app/app_routes.dart';
import 'package:drunk_diary/features/activity/screens/diary_screen.dart';
import 'package:drunk_diary/features/drink_logs/screens/shelf_screen.dart';
import 'package:drunk_diary/features/home/screens/home_screen.dart';
import 'package:drunk_diary/features/auth/screens/login_screen.dart';
import 'package:drunk_diary/features/auth/screens/onboarding_screen.dart';
import 'package:drunk_diary/app/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/auth/auth_gate.dart';
import 'core/firebase/firebase_options.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/search/screens/search_screen.dart';
import 'features/admin/screens/admin_settings_screen.dart';
import 'splash/splash_screen.dart';
import 'features/activity/screens/stats_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:feedback/feedback.dart';
// imports

void main() async {
  // app execution starts here
  WidgetsFlutterBinding.ensureInitialized(); // ensure flutter engine is ready

  await Firebase.initializeApp(
    // connect flutter app to Firebase backend
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const ProviderScope(
      child: DrunkDiaryApp(),
    ),
  ); // launch the app
}

class DrunkDiaryApp extends StatelessWidget {
  // root widget of the application
  const DrunkDiaryApp({super.key}); // stateless because app-level config doesn't change

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
    return BetterFeedback(
      theme: FeedbackThemeData(
        background: const Color(0xFF121212),
        feedbackSheetColor: const Color(0xFF1E1E1E),
        activeFeedbackModeColor: const Color(0xFFFF5722),
        brightness: Brightness.dark,
      ),
      child: MaterialApp(
        //root container for material design app
        title: 'DrunkDiary', // app-switcher name
        debugShowCheckedModeBanner: false, // disable debug banner
        navigatorObservers: [observer],

        home: const AuthGate(), //  AuthGate handles routing based on auth state

        routes: {
          AppRoutes.auth: (context) => AuthGate(),
          AppRoutes.splash: (context) => const SplashScreen(),
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.home: (context) => HomeScreen(),
          AppRoutes.onboarding: (context) => OnboardingScreen(),
          AppRoutes.diary: (context) => DiaryScreen(),
          AppRoutes.profile: (context) => ProfileScreen(), // ☑️
          AppRoutes.shelf: (context) => ShelfScreen(),
          AppRoutes.search: (context) => SearchScreen(), // ☑️
          AppRoutes.stats: (context) => const StatsScreen(),
          AppRoutes.adminSettings: (context) => const AdminSettingsScreen(),
        },

        theme: AppThemes.darkTheme,
      ),
    );
  }
}
