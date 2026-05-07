import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../widgets/onboarding_components.dart';

class OnboardingScreen extends StatefulWidget {
  static const routeName = '/onboarding';
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int currentStep = 1;
  static const int totalPerceivedSteps = 5;

  bool isLoading = false;
  bool isBlocking = false;

  // Data
  bool? isLegalAge;
  String username = '';
  bool isUsernameAvailable = false;
  bool isCheckingUsername = false;
  String? usernameError;

  final Set<String> selectedDrinkPreferences = {};
  final Set<String> selectedTasteProfile = {};
  final Set<String> selectedDrinkingContext = {};
  final Set<String> selectedDiscoveryStyle = {};

  final PageController _pageController = PageController();

  void _nextStep() {
    if (currentStep < totalPerceivedSteps) {
      setState(() => currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (currentStep > 1) {
      if (isBlocking) {
        setState(() {
          isBlocking = false;
          isLegalAge = null;
        });
        return;
      }
      setState(() => currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _previousStep();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        body: isBlocking ? _buildBlockScreen() : _buildOnboardingFlow(),
      ),
    );
  }

  Widget _buildOnboardingFlow() {
    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _ageCheckStep(),
        _usernameStep(),
        _tasteStep(),
        _goalStep(),
        _finalStep(),
      ],
    );
  }

  Widget _ageCheckStep() {
    return OnboardingLayout(
      progress: OnboardingProgressBar(
        currentStep: 1,
        totalSteps: totalPerceivedSteps,
      ),
      title: 'Are you of legal drinking age in your country?',
      subtitle: 'We ask this to keep DrunkDiary compliant and safe.',
      body: Column(
        children: [
          OnboardingChoiceCard(
            label: 'Yes, I am of legal age',
            isSelected: isLegalAge == true,
            onTap: () {
              setState(() => isLegalAge = true);
              HapticFeedback.lightImpact();
              _nextStep();
            },
          ),
          OnboardingChoiceCard(
            label: 'No, I am not',
            isSelected: isLegalAge == false,
            onTap: () {
              setState(() => isBlocking = true);
              HapticFeedback.mediumImpact();
            },
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

  Widget _usernameStep() {
    return OnboardingLayout(
      progress: OnboardingProgressBar(
        currentStep: 2,
        totalSteps: totalPerceivedSteps,
      ),
      title: 'What should the community call you?',
      subtitle: 'This is your unique identity on DrunkDiary.',
      body: Column(
        children: [
          TextField(
            autofocus: true,
            style: AppTextStyles.body.copyWith(fontSize: 18),
            onChanged: (value) {
              setState(() {
                username = value.toLowerCase();
              });
              _checkUsername(value);
            },
            decoration: InputDecoration(
              hintText: 'your_name',
              errorText: usernameError,
              prefixText: '@ ',
              prefixStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
              suffixIcon: isCheckingUsername
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : isUsernameAvailable
                      ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                      : null,
            ),
          ),
        ],
      ),
      cta: OnboardingButton(
        label: 'Continue',
        isEnabled: isUsernameAvailable,
        onPressed: _nextStep,
      ),
    );
  }

  Widget _tasteStep() {
    final options = [
      'Beer 🍺',
      'Whisky 🥃',
      'Cocktails 🍸',
      'Wine 🍷',
      'Vodka / Gin / Rum 🍸',
      'I’m still exploring 🔎',
    ];

    return OnboardingLayout(
      progress: OnboardingProgressBar(
        currentStep: 3,
        totalSteps: totalPerceivedSteps,
      ),
      title: 'What’s usually in your glass?',
      subtitle: 'Tell us your favorites so we can personalize your shelf.',
      body: Column(
        children: options.map((option) {
          final isSelected = selectedDrinkPreferences.contains(option);
          return OnboardingChoiceCard(
            label: option,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                if (isSelected) {
                  selectedDrinkPreferences.remove(option);
                } else {
                  selectedDrinkPreferences.add(option);
                }
              });
              HapticFeedback.selectionClick();
            },
          );
        }).toList(),
      ),
      cta: OnboardingButton(
        label: 'Continue',
        isEnabled: selectedDrinkPreferences.isNotEmpty,
        onPressed: _nextStep,
      ),
    );
  }

  Widget _goalStep() {
    final tasteOptions = [
      'Smooth & easy 🍹',
      'Strong & bold 🥃',
      'Fruity & sweet 🍓',
      'Bitter & hoppy 🍺',
      'Sour & tangy 🍋',
    ];

    return OnboardingLayout(
      progress: OnboardingProgressBar(
        currentStep: 4,
        totalSteps: totalPerceivedSteps,
      ),
      title: 'Why did you join DrunkDiary?',
      subtitle: 'Select what reflects your drinking style.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MY TASTE VIBE',
            style: AppTextStyles.caption.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
              color: Colors.white38,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: tasteOptions.map((option) {
              final isSelected = selectedTasteProfile.contains(option);
              return ChoiceChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      selectedTasteProfile.add(option);
                    } else {
                      selectedTasteProfile.remove(option);
                    }
                  });
                },
                selectedColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: const Color(0xFF1A1A1A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white10,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.hero),
          Text(
            'PREFERRED SETTING',
            style: AppTextStyles.caption.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
              color: Colors.white38,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...['House parties 🏠', 'Bars / Clubs 🍸', 'Casual nights 🛋️', 'Celebrations ✨'].map((option) {
            final isSelected = selectedDrinkingContext.contains(option);
            return OnboardingChoiceCard(
              label: option,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  if (isSelected) {
                    selectedDrinkingContext.remove(option);
                  } else {
                    selectedDrinkingContext.add(option);
                  }
                });
              },
            );
          }),
        ],
      ),
      cta: OnboardingButton(
        label: 'Continue',
        isEnabled: selectedTasteProfile.isNotEmpty && selectedDrinkingContext.isNotEmpty,
        onPressed: _nextStep,
      ),
    );
  }

  Widget _finalStep() {
    return OnboardingLayout(
      progress: OnboardingProgressBar(
        currentStep: 5,
        totalSteps: totalPerceivedSteps,
      ),
      title: 'Your shelf is ready.',
      subtitle: 'Let’s log your first memory.',
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(seconds: 1),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: const Icon(
                Icons.wine_bar_rounded,
                size: 120,
                color: Color(0xFFFFC107),
              ),
            );
          },
        ),
      ),
      cta: OnboardingButton(
        label: 'Enter DrunkDiary',
        isLoading: isLoading,
        onPressed: _finishOnboarding,
      ),
    );
  }

  Future<void> _checkUsername(String value) async {
    final cleaned = value.trim().toLowerCase();

    if (cleaned.length < 3) {
      setState(() {
        usernameError = 'Username must be at least 3 characters';
        isUsernameAvailable = false;
      });
      return;
    }

    setState(() {
      isCheckingUsername = true;
      usernameError = null;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('usernames')
          .doc(cleaned)
          .get();

      setState(() {
        isCheckingUsername = false;
        isUsernameAvailable = !doc.exists;
        usernameError = doc.exists ? 'Username already taken' : null;
      });
    } catch (e) {
      setState(() => isCheckingUsername = false);
    }
  }

  Future<void> _finishOnboarding() async {
    setState(() => isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    final cleanedUsername = username.trim().toLowerCase();

    final firestore = FirebaseFirestore.instance;
    final usernameRef = firestore.collection('usernames').doc(cleanedUsername);
    final userRef = firestore.collection('users').doc(user.uid);

    try {
      await firestore.runTransaction((transaction) async {
        final usernameSnap = await transaction.get(usernameRef);

        if (usernameSnap.exists) {
          throw Exception('USERNAME_TAKEN');
        }

        transaction.set(usernameRef, {'uid': user.uid});

        transaction.set(
          userRef,
          {
            'username': cleanedUsername,
            'usernameLowercase': cleanedUsername,
            'displayName': user.displayName ?? '',
            'displayNameLowercase': (user.displayName ?? '').toLowerCase(),
            'ageVerified': true,
            'legalAge': true,
            'drinkPreferences': selectedDrinkPreferences.toList(),
            'tasteProfile': selectedTasteProfile.toList(),
            'drinkingContext': selectedDrinkingContext.toList(),
            'onboardingCompleted': true,
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });

      await AnalyticsService().logSignUp('google');
      await AnalyticsService().logOnboardingComplete();
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().contains('USERNAME_TAKEN') ? 'Username taken.' : 'Error saving profile.')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }
}
