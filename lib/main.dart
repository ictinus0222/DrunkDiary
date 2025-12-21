import 'package:drunk_diary/routes/app_routes.dart';
import 'package:drunk_diary/screens/home/home_screen.dart';
import 'package:drunk_diary/screens/login_screen.dart';
import 'package:drunk_diary/screens/onboarding_screen.dart';
import 'package:drunk_diary/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth/auth_gate.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const DrunkDiaryApp());
}

class DrunkDiaryApp extends StatelessWidget {
  const DrunkDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DrunkDiary',
      debugShowCheckedModeBanner: false,

      home : const AuthGate(),

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