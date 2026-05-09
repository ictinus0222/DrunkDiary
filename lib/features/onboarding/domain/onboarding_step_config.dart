import 'package:flutter/material.dart';

enum OnboardingStepType {
  educational,
  setup,
  finalCta,
}

class OnboardingStepConfig {
  final String id;
  final String headline;
  final String subtext;
  final String analyticsName;
  final OnboardingStepType type;
  final Widget? visualElement; // Optional specific widget for the screen

  const OnboardingStepConfig({
    required this.id,
    required this.headline,
    required this.subtext,
    required this.analyticsName,
    required this.type,
    this.visualElement,
  });
}
