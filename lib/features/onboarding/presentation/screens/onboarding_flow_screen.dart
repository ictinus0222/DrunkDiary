import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/education_step_card.dart';
import '../widgets/onboarding_components.dart';
import '../../domain/onboarding_step_config.dart';
import '../../../../core/analytics/funnel_tracker.dart';
import '../../../../core/theme/app_colors.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/setup_steps/age_check_step.dart';
import '../widgets/setup_steps/username_step.dart';
import '../widgets/setup_steps/camera_log_step.dart';

import '../../../drink_logs/models/drink_model_dto.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/constants/reaction_config.dart';
import '../../../alcohol/models/alcohol_model.dart';
import '../../../alcohol/repositories/alcohol_repository.dart';

class OnboardingFlowScreen extends ConsumerStatefulWidget {
  static const routeName = '/onboarding';
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  late PageController _pageController;
  bool _isBlocking = false;

  // Diary Completion Screen fields
  bool _showUploadProgressScreen = false;
  bool _uploadFinished = false;
  double _uploadPercent = 0.0;
  bool _animPhotoChecked = false;
  bool _animBottleChecked = false;
  bool _animReactionChecked = false;
  bool _animShelfChecked = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(funnelTrackerProvider).logOnboardingStarted();
      _requestCameraPermission();
      // Precache background images for smooth cross-fades
      precacheImage(const AssetImage('assets/images/drinking_diary.png'), context);
      precacheImage(const AssetImage('assets/images/log_moment.png'), context);
      precacheImage(const AssetImage('assets/images/shelf.png'), context);
      precacheImage(const AssetImage('assets/images/share_drinks.png'), context);
    });
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isDenied || status.isRestricted) {
      await Permission.camera.request();
    }
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
    FocusScope.of(context).unfocus();

    final state = ref.read(onboardingProvider);
    if (state.currentStepIndex < state.steps.length - 1) {
      // Update state first to avoid notifying unmounted elements after animation
      ref.read(onboardingProvider.notifier).nextStep();
      final nextState = ref.read(onboardingProvider);
      final nextStep = nextState.steps[nextState.currentStepIndex];
      ref.read(funnelTrackerProvider).logOnboardingStep(
        nextState.currentStepIndex,
        nextStep.analyticsName,
      );

      await _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutQuart,
      );
    } else {
      await _finish();
    }
    
    if (mounted) {
      _isAnimating = false;
    }
  }

  void _back() async {
    if (_isAnimating) return;
    _isAnimating = true;
    FocusScope.of(context).unfocus();

    final state = ref.read(onboardingProvider);
    if (state.currentStepIndex > 0) {
      // Update state first
      ref.read(onboardingProvider.notifier).previousStep();

      await _pageController.previousPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutQuart,
      );
    }
    
    if (mounted) {
      _isAnimating = false;
    }
  }

  Future<void> _finish() async {
    final state = ref.read(onboardingProvider);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cleanedUsername = state.username.trim().toLowerCase();
    final firestore = FirebaseFirestore.instance;

    final hasFirstLog = state.firstLogAlcoholName != null;
    final hasPhoto = state.firstLogPhotoPath != null;

    if (hasFirstLog) {
      setState(() {
        _showUploadProgressScreen = true;
      });

      // Animate the checklist sequentially
      await Future.delayed(const Duration(milliseconds: 400));
      if (hasPhoto) {
        if (mounted) setState(() => _animPhotoChecked = true);
        await Future.delayed(const Duration(milliseconds: 300));
      }
      if (mounted) setState(() => _animBottleChecked = true);
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) setState(() => _animReactionChecked = true);
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) setState(() => _animShelfChecked = true);
      await Future.delayed(const Duration(milliseconds: 200));
    } else {
      ref.read(onboardingProvider.notifier).setLoading(true);
    }

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

      if (hasFirstLog) {
        final isCustom = state.firstLogIsCustom ?? true;
        final log = DrinkLogModel(
          id: '',
          creatorId: user.uid,
          username: cleanedUsername,
          userPhotoUrl: user.photoURL,
          alcoholId: isCustom ? null : state.firstLogAlcoholId,
          alcoholName: state.firstLogAlcoholName ?? 'Unknown drink',
          alcoholType: state.firstLogAlcoholType ?? 'Custom',
          isCustom: isCustom,
          customName: isCustom ? state.firstLogAlcoholName : null,
          reaction: state.firstLogKind == LogKind.review ? null : state.firstLogReaction,
          rating: state.firstLogKind == LogKind.review ? state.firstLogRating : null,
          note: state.firstLogNote,
          logKind: state.firstLogKind ?? LogKind.log,
          createdAt: DateTime.now(),
          isPrivate: state.initialPrivacyPreference,
          acceptedParticipantIds: [user.uid],
          participantCount: 1,
        );

        final logRef = await firestore.collection('drink_logs').add(log.toMap());

        await firestore.collection('drink_log_participants').doc('${logRef.id}_${user.uid}').set({
          'logId': logRef.id,
          'userId': user.uid,
          'status': 'accepted',
          'role': 'creator',
          'createdAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        });

        if (hasPhoto) {
          final localPhotoPath = state.firstLogPhotoPath!;
          final file = File(localPhotoPath);

          if (await file.exists()) {
            final storageRef = FirebaseStorage.instance
                .ref()
                .child('drink_logs')
                .child(user.uid)
                .child('${logRef.id}.jpg');

            final uploadTask = storageRef.putFile(file);

            uploadTask.snapshotEvents.listen((event) {
              if (mounted) {
                setState(() {
                  _uploadPercent = event.bytesTransferred / event.totalBytes;
                });
              }
            });

            await uploadTask;
            final downloadUrl = await storageRef.getDownloadURL();

            await logRef.update({
              'photoUrl': downloadUrl,
              'photoUploadedAt': FieldValue.serverTimestamp(),
            });

            try {
              await file.delete();
            } catch (_) {}
          }
        }

        await ref.read(analyticsServiceProvider).logEvent(
          name: 'first_log_completed',
          parameters: {
            'drink_name': state.firstLogAlcoholName ?? 'Unknown',
            'reaction': state.firstLogKind == LogKind.review
                ? state.firstLogRating?.toString() ?? '0.0'
                : state.firstLogReaction?.value ?? 'liked',
            'log_kind': state.firstLogKind?.name ?? 'log',
          },
        );
      }

      if (hasFirstLog) {
        setState(() {
          _uploadFinished = true;
        });
        await Future.delayed(const Duration(milliseconds: 1500));
      }

      await ref.read(funnelTrackerProvider).logOnboardingCompleted();
      await ref.read(funnelTrackerProvider).logFirstLogCtaClicked();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ref.read(onboardingProvider.notifier).setLoading(false);
        setState(() {
          _showUploadProgressScreen = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().contains('USERNAME_TAKEN') ? 'Username taken.' : 'Error saving profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showUploadProgressScreen) {
      return _buildUploadProgressScreen();
    }

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

          // Background cross-fades — isolated in RepaintBoundary + AnimatedBuilder
          // so only this layer repaints on every scroll frame, not the full tree.
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _pageController,
                builder: (ctx, _) {
                  final page = (_pageController.hasClients &&
                          _pageController.positions.length == 1)
                      ? (_pageController.page ?? 0.0)
                      : 0.0;

                  double op0 = (1.0 - page).clamp(0.0, 1.0);
                  double op1 = (1.0 - (page - 1.0).abs()).clamp(0.0, 1.0);
                  double op2 = (1.0 - (page - 2.0).abs()).clamp(0.0, 1.0);
                  double op3 = (1.0 - (page - 3.0).abs()).clamp(0.0, 1.0);
                  double opOverlay = page <= 3.0 ? 1.0 : (4.0 - page).clamp(0.0, 1.0);

                  return Stack(
                    children: [
                      if (op0 > 0.01)
                        Positioned.fill(
                          child: Opacity(
                            opacity: op0,
                            child: Image.asset('assets/images/drinking_diary.png', fit: BoxFit.cover),
                          ),
                        ),
                      if (op1 > 0.01)
                        Positioned.fill(
                          child: Opacity(
                            opacity: op1,
                            child: Image.asset('assets/images/log_moment.png', fit: BoxFit.cover),
                          ),
                        ),
                      if (op2 > 0.01)
                        Positioned.fill(
                          child: Opacity(
                            opacity: op2,
                            child: Image.asset('assets/images/shelf.png', fit: BoxFit.cover),
                          ),
                        ),
                      if (op3 > 0.01)
                        Positioned.fill(
                          child: Opacity(
                            opacity: op3,
                            child: Image.asset('assets/images/share_drinks.png', fit: BoxFit.cover),
                          ),
                        ),
                      // Dark scrim — always present on educational steps
                      Positioned.fill(
                        child: Opacity(
                          opacity: opOverlay,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0x73000000), // 45% black
                                  Color(0xCC000000), // 80% black
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          RepaintBoundary(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.steps.length,
              itemBuilder: (context, index) {
                final step = state.steps[index];

                // Camera moment step
                if (step.id == 'log_anything') {
                  return RepaintBoundary(
                    child: CameraLogStep(
                      isActive: state.currentStepIndex == index,
                      onLogMoment: _next,
                      onNotDrinking: _next,
                    ),
                  );
                }

                if (step.type == OnboardingStepType.educational || step.type == OnboardingStepType.finalCta) {
                  return RepaintBoundary(
                    child: EducationStepCard(
                      headline: step.headline,
                      subtext: step.subtext,
                      ctaLabel: step.type == OnboardingStepType.finalCta ? 'Log Your First Drink' : 'Continue',
                      onNext: _next,
                      visual: _buildVisualForStep(step.id),
                    ),
                  );
                }

                return RepaintBoundary(
                  child: OnboardingLayout(
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
                  ),
                );
              },
            ),
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
      default:
        return Center(child: Text('Setup for ${step.id}', style: const TextStyle(color: Colors.white)));
    }
  }

  bool _isStepValid(String id, OnboardingState state) {
    switch (id) {
      case 'setup_username':
        return state.username.length >= 3;
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
    final state = ref.watch(onboardingProvider);
    switch (id) {
      case 'identity':
        return SvgPicture.asset(
          'assets/icons/drunk_diary_wordmark.svg',
          width: 300,
          fit: BoxFit.contain,
        );
      case 'build_shelf':
        if (state.firstLogAlcoholName != null) {
          return OnboardingShelfVisual(
            photoPath: state.firstLogPhotoPath,
            drinkName: state.firstLogAlcoholName!,
            reaction: state.firstLogReaction ?? DrinkReaction.liked,
            logKind: state.firstLogKind ?? LogKind.log,
            rating: state.firstLogRating,
          );
        }
        return const Icon(Icons.grid_view_rounded, size: 120, color: AppColors.amber);
      case 'social':
        return const SocialLogCardVisual();
      case 'final_cta':
        return const Icon(Icons.wine_bar_rounded, size: 120, color: AppColors.amber);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildUploadProgressScreen() {
    final state = ref.read(onboardingProvider);
    final hasPhoto = state.firstLogPhotoPath != null;
    final double progress = hasPhoto ? _uploadPercent : 1.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Welcome to DrunkDiary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              
              // Checklist Items
              if (hasPhoto) ...[
                _buildChecklistItem('Photo', _animPhotoChecked),
                const SizedBox(height: 12),
              ],
              _buildChecklistItem(hasPhoto ? 'Bottle' : 'Favorite Drink', _animBottleChecked),
              const SizedBox(height: 12),
              _buildChecklistItem('Reaction', _animReactionChecked),
              const SizedBox(height: 12),
              _buildChecklistItem('Shelf', _animShelfChecked),
              
              const SizedBox(height: 32),
              
              AnimatedCrossFade(
                firstChild: Column(
                  children: [
                    const Text(
                      'Creating your first entry...',
                      style: TextStyle(color: Colors.white60, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white10,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
                secondChild: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.black,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your diary has begun.',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                crossFadeState: _uploadFinished
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistItem(String label, bool isChecked) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isChecked ? Colors.white : Colors.white30,
            fontSize: 15,
            fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isChecked
              ? const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.amber,
                  key: ValueKey('checked'),
                  size: 22,
                )
              : const Icon(
                  Icons.circle_outlined,
                  color: Colors.white24,
                  key: ValueKey('unchecked'),
                  size: 22,
                ),
        ),
      ],
    );
  }
}

class OnboardingShelfVisual extends StatefulWidget {
  final String? photoPath;
  final String drinkName;
  final DrinkReaction reaction;
  final LogKind logKind;
  final double? rating;

  const OnboardingShelfVisual({
    super.key,
    this.photoPath,
    required this.drinkName,
    required this.reaction,
    this.logKind = LogKind.log,
    this.rating,
  });

  @override
  State<OnboardingShelfVisual> createState() => _OnboardingShelfVisualState();
}

class _OnboardingShelfVisualState extends State<OnboardingShelfVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  
  // Shelf board scales
  late final Animation<double> _bottomShelfScale;
  late final Animation<double> _topShelfScale;

  // Staggered scales for 7 bottles
  late final Animation<double> _bottleScale1; // Top Left
  late final Animation<double> _bottleScale2; // Top Center
  late final Animation<double> _bottleScale3; // Bottom Left 1
  late final Animation<double> _bottleScale4; // Bottom Left 2
  late final Animation<double> _bottleScale5; // Bottom Right 2
  late final Animation<double> _bottleScale6; // Bottom Right 1
  late final Animation<double> _newLogBottleScale; // Highlighted New Log (Top Right)

  late final Animation<double> _popupOpacity;
  late final Animation<double> _popupSlide;

  final _alcoholRepo = AlcoholRepository();
  List<AlcoholModel> _dbAlcohols = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Shelf boards
    _bottomShelfScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOutBack),
      ),
    );

    _topShelfScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.55, curve: Curves.easeOutBack),
      ),
    );

    // Staggered bottom shelf bottles (appear first)
    _bottleScale3 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.12, 0.42, curve: Curves.easeOutBack),
      ),
    );
    _bottleScale4 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.18, 0.48, curve: Curves.easeOutBack),
      ),
    );
    _bottleScale5 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.24, 0.54, curve: Curves.easeOutBack),
      ),
    );
    _bottleScale6 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.30, 0.60, curve: Curves.easeOutBack),
      ),
    );

    // Staggered top shelf bottles (appear second)
    _bottleScale1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.70, curve: Curves.easeOutBack),
      ),
    );
    _bottleScale2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.48, 0.78, curve: Curves.easeOutBack),
      ),
    );
    _newLogBottleScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.56, 0.86, curve: Curves.easeOutBack),
      ),
    );

    // Pop-up bubble pointing to the new log
    _popupOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.70, 0.95, curve: Curves.easeIn),
      ),
    );

    _popupSlide = Tween<double>(begin: 15.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.70, 0.95, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
    _loadAlcohols();
  }

  Future<void> _loadAlcohols() async {
    try {
      final alcohols = await _alcoholRepo.getAllAlcohols();
      if (mounted) {
        setState(() {
          _dbAlcohols = alcohols;
        });
      }
    } catch (_) {
      // Quietly fail and use fallbacks
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildBottle({
    required double width,
    required double height,
    required String name,
    required String imageUrl,
    required Animation<double> scaleAnimation,
    bool isUserPhoto = false,
  }) {
    final bool isEmptyUrl = imageUrl.isEmpty;
    return ScaleTransition(
      scale: scaleAnimation,
      child: SizedBox(
        width: width,
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: isUserPhoto
              ? Image.file(
                  File(imageUrl),
                  fit: BoxFit.cover,
                  width: double.infinity,
                )
              : (isEmptyUrl
                  ? Container(
                      color: Colors.amber.withValues(alpha: 0.1),
                      child: Center(
                        child: Icon(
                          Icons.local_bar_rounded,
                          color: Colors.amber,
                          size: width > 80 ? 44 : 26,
                        ),
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => Container(
                        color: const Color(0xFF2C2C2C),
                        child: Center(
                          child: SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white24),
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.amber.withValues(alpha: 0.1),
                        child: Center(
                          child: Icon(
                            Icons.local_bar_rounded,
                            color: Colors.amber,
                            size: width > 80 ? 44 : 26,
                          ),
                        ),
                      ),
                    )),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter out the user's logged drink if it matches the name of any database bottle
    final otherAlcohols = _dbAlcohols
        .where((a) => a.name.toLowerCase() != widget.drinkName.toLowerCase())
        .toList();

    // Default premium fallback values for up to 6 slots
    final fallbackNames = [
      'Macallan 12',
      'Chardonnay',
      'Lagavulin 16',
      'Glenfiddich 15',
      'Grey Goose',
      'Corona Extra'
    ];

    final fallbackImages = [
      'https://images.unsplash.com/photo-1527061011665-3652c757a4d4?w=150&q=80', // Whiskey
      'https://images.unsplash.com/photo-1506377247377-2a5b3b417ebb?w=150&q=80', // Wine
      'https://images.unsplash.com/photo-1569529465841-dfedd87500f1?w=150&q=80', // Whiskey 2
      'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=150&q=80', // Cocktail/spirit
      'https://images.unsplash.com/photo-1592751864109-eb3e07d0f12c?w=150&q=80', // Vodka/glass
      'https://images.unsplash.com/photo-1600788886242-5c96aabe3757?w=150&q=80', // Beer
    ];

    final names = List<String>.generate(6, (i) {
      if (otherAlcohols.length > i) {
        return otherAlcohols[i].name;
      }
      return fallbackNames[i];
    });

    final imageUrls = List<String>.generate(6, (i) {
      if (otherAlcohols.length > i &&
          otherAlcohols[i].imageUrl.isNotEmpty &&
          otherAlcohols[i].imageUrl.startsWith('http')) {
        return otherAlcohols[i].imageUrl;
      }
      return fallbackImages[i];
    });

    return Center(
      child: SizedBox(
        width: 400,
        height: 380,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // ── Bottom Shelf Wood Board ────────────────────────────────────
            Positioned(
              bottom: 30,
              child: ScaleTransition(
                scale: _bottomShelfScale,
                child: Container(
                  height: 12,
                  width: 350,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8D6E63),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Bottom Shelf Bottles ──────────────────────────────────────
            Positioned(
              left: 35,
              bottom: 42,
              child: _buildBottle(
                width: 70,
                height: 105,
                name: names[2],
                imageUrl: imageUrls[2],
                scaleAnimation: _bottleScale3,
              ),
            ),
            Positioned(
              left: 122,
              bottom: 42,
              child: _buildBottle(
                width: 70,
                height: 105,
                name: names[3],
                imageUrl: imageUrls[3],
                scaleAnimation: _bottleScale4,
              ),
            ),
            Positioned(
              left: 209,
              bottom: 42,
              child: _buildBottle(
                width: 70,
                height: 105,
                name: names[4],
                imageUrl: imageUrls[4],
                scaleAnimation: _bottleScale5,
              ),
            ),
            Positioned(
              right: 35,
              bottom: 42,
              child: _buildBottle(
                width: 70,
                height: 105,
                name: names[5],
                imageUrl: imageUrls[5],
                scaleAnimation: _bottleScale6,
              ),
            ),

            // ── Top Shelf Wood Board ───────────────────────────────────────
            Positioned(
              bottom: 175,
              child: ScaleTransition(
                scale: _topShelfScale,
                child: Container(
                  height: 12,
                  width: 350,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8D6E63),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Top Shelf Bottles ─────────────────────────────────────────
            Positioned(
              left: 50,
              bottom: 187,
              child: _buildBottle(
                width: 70,
                height: 105,
                name: names[0],
                imageUrl: imageUrls[0],
                scaleAnimation: _bottleScale1,
              ),
            ),
            Positioned(
              left: 150,
              bottom: 187,
              child: _buildBottle(
                width: 70,
                height: 105,
                name: names[1],
                imageUrl: imageUrls[1],
                scaleAnimation: _bottleScale2,
              ),
            ),

            // ── User's New Bottle (Most Recent - Highlighted on Top Right) ──
            Positioned(
              left: 250,
              bottom: 187,
              child: Builder(
                builder: (context) {
                  final hasPhoto = widget.photoPath != null && widget.photoPath!.isNotEmpty;
                  String bottleImageUrl = '';
                  
                  if (!hasPhoto) {
                    final matchingAlcohol = _dbAlcohols.firstWhere(
                      (a) => a.name.toLowerCase() == widget.drinkName.toLowerCase(),
                      orElse: () => AlcoholModel(id: '', name: '', brand: '', type: '', abv: 0.0, origin: '', description: '', imageUrl: ''),
                    );
                    bottleImageUrl = matchingAlcohol.imageUrl;
                  } else {
                    bottleImageUrl = widget.photoPath!;
                  }

                  return _buildBottle(
                    width: 100,
                    height: 140,
                    name: widget.drinkName,
                    imageUrl: bottleImageUrl,
                    scaleAnimation: _newLogBottleScale,
                    isUserPhoto: hasPhoto,
                  );
                }
              ),
            ),

            // ── Pop up bubble pointing to the user's most recent bottle ──
            Positioned(
              top: 15,
              left: 235,
              child: FadeTransition(
                opacity: _popupOpacity,
                child: AnimatedBuilder(
                  animation: _popupSlide,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _popupSlide.value),
                      child: child,
                    );
                  },
                  child: SizedBox(
                    width: 130,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.logKind == LogKind.review
                                    ? '⭐ ${widget.rating?.toStringAsFixed(1) ?? '0.0'}'
                                    : (widget.reaction == DrinkReaction.loved
                                        ? '😍'
                                        : widget.reaction == DrinkReaction.liked
                                            ? '🙂'
                                            : '👎'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  widget.drinkName,
                                  style: const TextStyle(
                                    fontFamily: 'DMSans',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CustomPaint(
                          size: const Size(10, 5),
                          painter: _TrianglePainter(Colors.amber),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Social Step: Mock Log Card Visual ─────────────────────────────────────────
class SocialLogCardVisual extends StatefulWidget {
  const SocialLogCardVisual({super.key});

  @override
  State<SocialLogCardVisual> createState() => _SocialLogCardVisualState();
}

class _SocialLogCardVisualState extends State<SocialLogCardVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _cardSlide;
  late final Animation<double> _cardFade;
  late final Animation<double> _tagsSlide;
  late final Animation<double> _tagsFade;
  late final Animation<double> _reactionFade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _cardFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.45, curve: Curves.easeOut)),
    );
    _cardSlide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic)),
    );
    _tagsFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.35, 0.7, curve: Curves.easeOut)),
    );
    _tagsSlide = Tween<double>(begin: 16, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.35, 0.7, curve: Curves.easeOutCubic)),
    );
    _reactionFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.6, 1.0, curve: Curves.easeOut)),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Center(
          child: Transform.translate(
            offset: Offset(0, _cardSlide.value),
            child: Opacity(
              opacity: _cardFade.value,
              child: Container(
                width: 300,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 40,
                      spreadRadius: 2,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Photo ─────────────────────────────────────────────
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Stack(
                        children: [
                          Image.asset(
                            'assets/images/share_drinks.png',
                            height: 110,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    const Color(0xFF1A1A1A),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Card body ──────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Yamazaki 18 Year',
                                      style: TextStyle(
                                        fontFamily: 'DMSans',
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Japanese Whisky',
                                      style: TextStyle(
                                        fontFamily: 'DMSans',
                                        fontSize: 12,
                                        color: Colors.white.withValues(alpha: 0.45),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              FadeTransition(
                                opacity: _reactionFade,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('😍', style: TextStyle(fontSize: 13)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Loved it',
                                        style: TextStyle(
                                          fontFamily: 'DMSans',
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // ── Tagged friends ─────────────────────────────
                          Transform.translate(
                            offset: Offset(0, _tagsSlide.value),
                            child: Opacity(
                              opacity: _tagsFade.value,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'WITH',
                                    style: TextStyle(
                                      fontFamily: 'DMSans',
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white.withValues(alpha: 0.3),
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 72,
                                        height: 28,
                                        child: Stack(
                                          children: [
                                            _buildAvatar('A', const Color(0xFF6C63FF), 0),
                                            _buildAvatar('M', const Color(0xFFFF6584), 22),
                                            _buildAvatar('R', const Color(0xFF43D399), 44),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'alex, meera & rafe',
                                          style: TextStyle(
                                            fontFamily: 'DMSans',
                                            fontSize: 13,
                                            color: Colors.white.withValues(alpha: 0.7),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(String initial, Color color, double left) {
    return Positioned(
      left: left,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
        ),
        child: Center(
          child: Text(
            initial,
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

