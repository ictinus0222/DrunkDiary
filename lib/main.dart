import 'package:drunk_diary/app/app_routes.dart';
import 'package:drunk_diary/features/drink_logs/screens/diary_timeline_screen.dart';
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
import 'splash/splash_screen.dart';
// imports

void main() async { // app execution starts here
  WidgetsFlutterBinding.ensureInitialized(); // ensure flutter engine is ready

  await Firebase.initializeApp(  // connect flutter app to Firebase backend
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const DrunkDiaryApp()); // launch the app
}

class DrunkDiaryApp extends StatelessWidget { // root widget of the application
  const DrunkDiaryApp({super.key});           // stateless because app-level config doesn't change

  @override
  Widget build(BuildContext context) {
    return MaterialApp( //root container for material design app
      title: 'DrunkDiary', // app-switcher name
      debugShowCheckedModeBanner: false, // disable debug banner

      home : const AuthGate(), //  AuthGate handles routing based on auth state

      routes: {
        AppRoutes.auth: (context) => AuthGate(),
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.home: (context) => HomeScreen(),
        AppRoutes.onboarding: (context) => OnboardingScreen(),
        AppRoutes.diary: (context) => DiaryTimelineScreen(),
        AppRoutes.profile: (context) => ProfileScreen(), // ☑️
        AppRoutes.shelf: (context) => ShelfScreen(),
        AppRoutes.search: (context) => SearchScreen(), // ☑️
      },

      theme: AppThemes.darkTheme,
    );
  }
}