import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OnboardingScreen extends StatefulWidget {
  static const routeName = '/onboarding';
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {

  int currentStep = 0;

  bool isLoading = false;

  DateTime? selectedDob;
  bool isAgeValid = false;

  static const int legalAge = 18; // can be country-based later

  final Set<String> selectedDrinkPreferences = {};
  final Set<String> selectedTasteProfile = {};
  final Set<String> selectedDrinkingContext = {};
  final Set<String> selectedDiscoveryStyle = {};
  String username = '';
  bool isUsernameAvailable = false;
  bool isCheckingUsername = false;
  String? usernameError;


  static const int totalSteps = 6;

  void _pickDob() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - legalAge),
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked == null) return;

    final age = _calculateAge(picked);

    setState(() {
      selectedDob = picked;
      isAgeValid = age >= legalAge;
    });
  }

  int _calculateAge(DateTime dateOfBirth) {
    final today = DateTime.now();
    int age = today.year - dateOfBirth.year;

    if (today.month < dateOfBirth.month ||
        (today.month == dateOfBirth.month && today.day < dateOfBirth.day)) {
      age--;
    }

    return age;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _progressIndicator(),
              const SizedBox(height: 32),
              _buildCurrentStep(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (currentStep) {
      case 0:
        return _dobStep();
      case 1:
        return _drinkPreferencesStep();
      case 2:
        return _tastePreferenceStep();
      case 3:
        return _drinkingContextStep();
      case 4:
        return _discoveryStyleStep();
      case 5:
        return _usernameStep();
      default:
        return const SizedBox.shrink();
    }
  }



  Widget _progressIndicator() {
    return Column(
      children: [
        Text(
          'Step ${currentStep + 1} of $totalSteps',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalSteps, (index) {
              final isActive = index <= currentStep;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                    ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade700,
                ),
              );
            }),
        ),
      ],
    );
  }


  Widget _dobStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'When were you born?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        const Text(
          'We need this to make sure you’re legally allowed to drink.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),

        const SizedBox(height: 32),

        OutlinedButton(
          onPressed: _pickDob,
          child: Text(
            selectedDob == null
                ? 'Select date of birth'
                : DateFormat.yMMMMd().format(selectedDob!),
          ),
        ),

        const SizedBox(height: 20),

        if (selectedDob != null && !isAgeValid)
          const Text(
            'You must be of legal drinking age to use this app.',
            style: TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),

        const SizedBox(height: 32),

        ElevatedButton(
          onPressed: isAgeValid
              ? () {
            setState(() => currentStep = 1);
          }
              : null,
          child: const Text('Continue'),
        ),
      ],
    );
  }


  Widget _drinkPreferencesStep() {
    final options = [
      'Beer 🍺',
      'Whisky 🥃',
      'Cocktails 🍸',
      'Wine 🍷',
      'Vodka / Gin / Rum',
      'I just try whatever’s there',
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'What do you usually drink?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          const Text(
            'Select all that apply. This helps us tailor your experience.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 32),

          ...options.map((option) {
            final isSelected = selectedDrinkPreferences.contains(option);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ChoiceChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    if (isSelected) {
                      selectedDrinkPreferences.remove(option);
                    } else {
                      selectedDrinkPreferences.add(option);
                    }
                  });
                },
              ),
            );
          }),

          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: selectedDrinkPreferences.isNotEmpty
                ? () {
              setState(() => currentStep = 2);
            }
            : null,
            child: const Text('Continue'),
          ),
        ],
    );
  }

  Widget _tastePreferenceStep() {
    final options = [
      'Smooth & easy 🍹',
      'Strong & bold 🥃',
      'Fruity & sweet 🍓',
      'Bitter & hoppy 🍺',
      'Sour & tangy 🍋',
      'Doesn’t matter - I drink anything! 🍻',
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'What kind of drinks do you enjoy?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        const Text(
          'This helps us suggest better options.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),

        const SizedBox(height: 32),

        ...options.map((option) {
          final isSelected = selectedTasteProfile.contains(option);

          return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ChoiceChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (_) {
            setState(() {
              if (isSelected) {
                selectedTasteProfile.remove(option);
          } else {
                selectedTasteProfile.add(option);
              }
          });
            },
          ),
        );
        }),

        const SizedBox(height: 32),

        ElevatedButton(
          onPressed: selectedTasteProfile.isNotEmpty
              ? () {
            setState(() => currentStep = 3);
          }
          : null,
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _drinkingContextStep() {
    final options = [
      'House parties',
      'Bars / clubs',
      'Celebrations (birthdays, weddings)',
      'Casual nights with friends',
      'Rarely / socially',
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'When do you usually drink?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        const Text(
          'Select all that apply.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),

        const SizedBox(height: 32),

        ...options.map((option) {
          final isSelected = selectedDrinkingContext.contains(option);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ChoiceChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  if (isSelected) {
                    selectedDrinkingContext.remove(option);
                  } else {
                    selectedDrinkingContext.add(option);
                  }
                });
              },
            ),
          );
        }),

        const SizedBox(height: 32),

        ElevatedButton(
          onPressed: selectedDrinkingContext.isNotEmpty
              ? () {
            setState(() => currentStep = 4); // Step 5 next
          }
              : null,
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _discoveryStyleStep() {
    final options = [
      'Friends’ recommendations',
      'Price',
      'Brand reputation',
      'What’s available at the party/bar',
      'Social media / hype',
      'I just go with the moment',
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'How do you usually decide what to try?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        const Text(
          'There’s no right answer.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),

        const SizedBox(height: 32),

        ...options.map((option) {
          final isSelected = selectedDiscoveryStyle.contains(option);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ChoiceChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  if (isSelected) {
                    selectedDiscoveryStyle.remove(option);
                  } else {
                    selectedDiscoveryStyle.add(option);
                  }
                });
              },
            ),
          );
        }),

        const SizedBox(height: 32),

        ElevatedButton(
          onPressed: selectedDrinkingContext.isNotEmpty
              ? () {
            setState(() => currentStep = 5); // Step 5 next
          }
              : null,
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _usernameStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Choose a username',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        const Text(
          'This is how others will see you.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),

        const SizedBox(height: 32),

        TextField(
          onChanged: (value) {
            setState(() {
              username = value.toLowerCase();
            });
            _checkUsername(value);
          },
          decoration: InputDecoration(
            hintText: 'username',
            errorText: usernameError,
            prefixText: '@',
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
                ? const Icon(Icons.check, color: Colors.green)
                : null,
          ),
        ),

        const SizedBox(height: 32),

        ElevatedButton(
          onPressed: isUsernameAvailable && !isLoading
              ? _finishOnboarding
              : null,
          child: isLoading
              ? const CircularProgressIndicator(strokeWidth: 2)
              : const Text('Finish'),
        ),
      ],
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

    final doc = await FirebaseFirestore.instance
        .collection('usernames')
        .doc(cleaned)
        .get();

    setState(() {
      isCheckingUsername = false;
      isUsernameAvailable = !doc.exists;
      usernameError = doc.exists ? 'Username already taken' : null;
    });
  }



  Future<void> _finishOnboarding() async {
    setState(() => isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    final cleanedUsername = username.trim().toLowerCase();

    // 🔒 Hard guard
    if (cleanedUsername.isEmpty || cleanedUsername.length < 3) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a valid username.'),
        ),
      );
      return;
    }

    final firestore = FirebaseFirestore.instance;
    final usernameRef = firestore.collection('usernames').doc(cleanedUsername);
    final userRef = firestore.collection('users').doc(user.uid);

    try {
      await firestore.runTransaction((transaction) async {
        final usernameSnap = await transaction.get(usernameRef);

        // ❌ Username already exists
        if (usernameSnap.exists) {
          throw Exception('USERNAME_TAKEN');
        }

        // ✅ Claim username
        transaction.set(usernameRef, {'uid': user.uid});

        // ✅ Save user profile
        transaction.set(
          userRef,
          {
            'username': cleanedUsername,
            'dob': selectedDob,
            'ageVerified': true,
            'drinkPreferences': selectedDrinkPreferences.toList(),
            'tasteProfile': selectedTasteProfile.toList(),
            'drinkingContext': selectedDrinkingContext.toList(),
            'discoveryStyle': selectedDiscoveryStyle.toList(),
            'onboardingCompleted': true,
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });
    } catch (e) {
      setState(() => isLoading = false);

      if (e.toString().contains('USERNAME_TAKEN')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Username already taken. Try another.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
          ),
        );
      }

      return;
    }

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home',
          (route) => false,
    );
  }




}
