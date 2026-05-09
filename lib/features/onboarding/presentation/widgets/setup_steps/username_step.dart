import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/onboarding_provider.dart';
import '../../../../../core/theme/app_text_styles.dart';

class UsernameStep extends ConsumerStatefulWidget {
  const UsernameStep({super.key});

  @override
  ConsumerState<UsernameStep> createState() => _UsernameStepState();
}

class _UsernameStepState extends ConsumerState<UsernameStep> {
  String? _error;
  bool _isChecking = false;

  Future<void> _checkUsername(String value) async {
    final cleaned = value.trim().toLowerCase();
    if (cleaned.length < 3) {
      setState(() => _error = 'Min 3 characters');
      return;
    }

    setState(() {
      _isChecking = true;
      _error = null;
    });

    try {
      final doc = await FirebaseFirestore.instance.collection('usernames').doc(cleaned).get();
      if (mounted) {
        setState(() {
          _isChecking = false;
          _error = doc.exists ? 'Username taken' : null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    
    return Column(
      children: [
        TextField(
          autofocus: true,
          style: AppTextStyles.body.copyWith(fontSize: 18),
          onChanged: (value) {
            ref.read(onboardingProvider.notifier).setUsername(value);
            _checkUsername(value);
          },
          decoration: InputDecoration(
            hintText: 'your_name',
            errorText: _error,
            prefixText: '@ ',
            prefixStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
            suffixIcon: _isChecking
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
