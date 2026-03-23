import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatelessWidget {
  static const routeName = '/splash';
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // Matches app dark theme
      body: Center(
        child: SvgPicture.asset(
          'assets/icons/drunk_diary_wordmark.svg',
          width: 240,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
