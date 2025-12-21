import 'package:drunk_diary/routes/app_routes.dart';
import 'package:drunk_diary/screens/home/home_screen.dart';
import 'package:drunk_diary/screens/auth_screens/login_screen.dart';
import 'package:drunk_diary/screens/auth_screens/onboarding_screen.dart';
import 'package:drunk_diary/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth/auth_gate.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
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
      },

      theme: AppThemes.darkTheme,
    );
  }
}