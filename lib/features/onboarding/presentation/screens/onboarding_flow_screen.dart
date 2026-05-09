import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/education_step_card.dart';
import '../widgets/onboarding_components.dart';
import '../../domain/onboarding_step_config.dart';
import '../../../../core/analytics/funnel_tracker.dart';
import '../../../../core/theme/app_colors.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../widgets/setup_steps/age_check_step.dart';
import '../widgets/setup_steps/username_step.dart';
import '../widgets/setup_steps/preferences_step.dart';
import '../widgets/setup_steps/privacy_step.dart';
import '../providers/post_onboarding_action_handler.dart';

class OnboardingFlowScreen extends ConsumerStatefulWidget {
  static const routeName = '/onboarding';
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  late PageController _pageController;
  bool _isBlocking = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Log start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(funnelTrackerProvider).logOnboardingStarted();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _isAnimating = false;

  void _next() async {
    if (_isAnimating) return;
    _isAnimating = true;

    final state = ref.read(onboardingProvider);
    if (state.currentStepIndex < state.steps.length - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutQuart,
      );
      
      ref.read(onboardingProvider.notifier).nextStep();
      final nextState = ref.read(onboardingProvider);
      final nextStep = nextState.steps[nextState.currentStepIndex];
      ref.read(funnelTrackerProvider).logOnboardingStep(
        nextState.currentStepIndex,
        nextStep.analyticsName,
      );
    } else {
      await _finish();
    }
    _isAnimating = false;
  }

  void _back() async {
    if (_isAnimating) return;
    _isAnimating = true;

    final state = ref.read(onboardingProvider);
    if (state.currentStepIndex > 0) {
      await _pageController.previousPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutQuart,
      );
      ref.read(onboardingProvider.notifier).previousStep();
    }
    _isAnimating = false;
  }

  Future<void> _finish() async {
    final state = ref.read(onboardingProvider);
    ref.read(onboardingProvider.notifier).setLoading(true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cleanedUsername = state.username.trim().toLowerCase();
    final firestore = FirebaseFirestore.instance;

    try {
      await firestore.runTransaction((transaction) async {
        final usernameRef = firestore.collection('usernames').doc(cleanedUsername);
        final userRef = firestore.collection('users').doc(user.uid);

        final usernameSnap = await transaction.get(usernameRef);
        if (usernameSnap.exists) throw Exception('USERNAME_TAKEN');

        transaction.set(usernameRef, {'uid': user.uid});
        transaction.set(
          userRef,
          {
            'username': cleanedUsername,
            'usernameLowercase': cleanedUsername,
            'displayName': user.displayName ?? cleanedUsername,
            'displayNameLowercase': (user.displayName ?? cleanedUsername).toLowerCase(),
            'ageVerified': true,
            'legalAge': true,
            'isPrivate': state.initialPrivacyPreference,
            'onboardingCompleted': true,
            'onboardingCompletedAt': FieldValue.serverTimestamp(),
            'onboardingVersion': '2.0.0', // Refined version
            'onboardingSkipped': false,
            'preferredDrinkCategories': state.preferredDrinkCategories.toList(),
            'initialPrivacyPreference': state.initialPrivacyPreference,
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });

      // Set guidance for first-log
      ref.read(postOnboardingHandlerProvider.notifier).setShouldShowFirstLogGuidance(true);
      await ref.read(funnelTrackerProvider).logOnboardingCompleted();
      await ref.read(funnelTrackerProvider).logFirstLogCtaClicked();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ref.read(onboardingProvider.notifier).setLoading(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().contains('USERNAME_TAKEN') ? 'Username taken.' : 'Error saving profile.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final isReducedMotion = MediaQuery.of(context).accessibleNavigation;

    if (_isBlocking) {
      return _buildBlockScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          // Ambient Background Parallax
          if (!isReducedMotion)
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(seconds: 2),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      state.currentStepIndex % 2 == 0 ? -0.5 : 0.5,
                      state.currentStepIndex % 3 == 0 ? -0.5 : 0.5,
                    ),
                    colors: [
                      AppColors.amber.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                    radius: 1.5,
                  ),
                ),
              ),
            ),

          PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.steps.length,
            itemBuilder: (context, index) {
              final step = state.steps[index];
              
              if (step.type == OnboardingStepType.educational || step.type == OnboardingStepType.finalCta) {
                return EducationStepCard(
                  headline: step.headline,
                  subtext: step.subtext,
                  ctaLabel: step.type == OnboardingStepType.finalCta ? 'Log Your First Drink' : 'Continue',
                  onNext: _next,
                  visual: _buildVisualForStep(step.id),
                );
              }
              
              return OnboardingLayout(
                progress: const SizedBox.shrink(),
                title: step.headline,
                subtitle: step.subtext,
                body: _buildSetupStep(step),
                cta: (step.id == 'setup_age' || step.id == 'privacy') ? null : OnboardingButton(
                  label: 'Continue',
                  isLoading: state.isLoading,
                  isEnabled: _isStepValid(step.id, state),
                  onPressed: _next,
                ),
              );
            },
          ),
          
          // Persistent Progress Indicator for Setup steps
          if (state.steps[state.currentStepIndex].type == OnboardingStepType.setup)
            Positioned(
              top: 60,
              left: 64, // Shifted to make room for back button
              right: 24,
              child: OnboardingProgressBar(
                currentStep: _getSetupStepIndex(state),
                totalSteps: _getSetupTotalSteps(state),
              ),
            ),

          // Persistent Back Button
          if (state.currentStepIndex > 0 && !_isBlocking)
            Positioned(
              top: 48,
              left: 12,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
                onPressed: _back,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBlockScreen() {
    return OnboardingLayout(
      progress: const SizedBox.shrink(),
      title: 'DrunkDiary is for legal-age users only.',
      subtitle: 'Come back when you\'re eligible.',
      body: const Center(
        child: Icon(
          Icons.lock_person_rounded,
          size: 80,
          color: Colors.white24,
        ),
      ),
      cta: OnboardingButton(
        label: 'Exit',
        onPressed: () => SystemNavigator.pop(),
      ),
    );
  }

  Widget _buildSetupStep(OnboardingStepConfig step) {
    switch (step.id) {
      case 'setup_age':
        return AgeCheckStep(
          onNext: _next,
          onBlock: () => setState(() => _isBlocking = true),
        );
      case 'setup_username':
        return const UsernameStep();
      case 'setup_preferences':
        return const PreferencesStep();
      case 'privacy':
        return PrivacyStep(onNext: _next);
      default:
        return Center(child: Text('Setup for ${step.id}', style: const TextStyle(color: Colors.white)));
    }
  }

  bool _isStepValid(String id, OnboardingState state) {
    switch (id) {
      case 'setup_username':
        return state.username.length >= 3;
      case 'setup_preferences':
        return state.preferredDrinkCategories.isNotEmpty;
      default:
        return true;
    }
  }

  int _getSetupStepIndex(OnboardingState state) {
    final setupSteps = state.steps.where((s) => s.type == OnboardingStepType.setup).toList();
    final currentStep = state.steps[state.currentStepIndex];
    return setupSteps.indexOf(currentStep) + 1;
  }

  int _getSetupTotalSteps(OnboardingState state) {
    return state.steps.where((s) => s.type == OnboardingStepType.setup).length;
  }

  Widget _buildVisualForStep(String id) {
    switch (id) {
      case 'identity':
        return const Icon(Icons.auto_stories_rounded, size: 120, color: AppColors.amber);
      case 'log_anything':
        return const Icon(Icons.local_bar_rounded, size: 120, color: AppColors.amber);
      case 'build_shelf':
        return const Icon(Icons.grid_view_rounded, size: 120, color: AppColors.amber);
      case 'social':
        return const Icon(Icons.people_alt_rounded, size: 120, color: AppColors.amber);
      case 'final_cta':
        return const Icon(Icons.wine_bar_rounded, size: 120, color: AppColors.amber);
      default:
        return const SizedBox.shrink();
    }
  }
}
