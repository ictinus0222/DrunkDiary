import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/splash_screen.dart';

class AuthGate extends StatelessWidget {
  static const routeName = '/auth';
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>( // listen to auth state changes continuously => StreamBuilder listens forever
      stream: FirebaseAuth.instance.authStateChanges(), // whenever auth state changes (login/logout) => widget rebuilds
      builder: (context, authSnapshot) {
        //  Auth loading => SplashScreen()
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        //  Not logged in => LoginScreen()
        if (!authSnapshot.hasData) {
          return const LoginScreen();
        }

        final user = authSnapshot.data!;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(), // one time fetch => do not need real-time updates

          builder: (context, userSnapshot) {
            //  Firestore loading => SplashScreen()
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            //  User doc DOES NOT exist / missing => onboarding
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const OnboardingScreen();
            }

            final data =                                       // Reading firestore data
            userSnapshot.data!.data() as Map<String, dynamic>; // safe to cast to a map since we checked existence

            final onboardingCompleted =
                data['onboardingCompleted'] ?? false;      // get onboarding status, default to false if missing

            // Onboarding done => HomeScreen
            if (onboardingCompleted) {
              return const HomeScreen();
            }

            // Onboarding not done => OnboardingScreen
            return const OnboardingScreen();
          },
        );
      },
    );
  }
}


