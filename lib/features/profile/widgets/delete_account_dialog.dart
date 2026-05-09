import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/services/google_auth_service.dart';
import '../repositories/account_deletion_repository.dart';

class DeleteAccountDialog extends ConsumerStatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  ConsumerState<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<DeleteAccountDialog> {
  bool isDeleting = false;
  String? errorMessage;

  Future<void> _handleDelete() async {
    setState(() {
      isDeleting = true;
      errorMessage = null;
    });

    try {
      await ref.read(accountDeletionRepositoryProvider).deleteUserAccount();
      
      if (mounted) {
        // Navigate to root so AuthGate takes over
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (e == 'reauthentication-required') {
        _handleReauthAndRetry();
      } else {
        setState(() {
          errorMessage = 'Error: $e';
          isDeleting = false;
        });
      }
    }
  }

  Future<void> _handleReauthAndRetry() async {
    // If deletion fails due to an old session, we log them out 
    // and send them to login to get a fresh session.
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      // Navigate to root so AuthGate takes over
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.1),
              blurRadius: 40,
              spreadRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Danger Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Delete Account?',
              style: AppTextStyles.section.copyWith(
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            
            Text(
              'This action is final and cannot be undone. All your data will be wiped.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Warning Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  _buildImpactItem(Icons.history_edu, 'Drink logs & Diary'),
                  const SizedBox(height: 12),
                  _buildImpactItem(Icons.photo_library, 'All uploaded photos'),
                  const SizedBox(height: 12),
                  _buildImpactItem(Icons.people_outline, 'Friends & Interactions'),
                ],
              ),
            ),
            
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: isDeleting ? null : _handleDelete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Delete Permanently',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white38,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Keep My Account'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white30),
        const SizedBox(width: 12),
        Text(
          text,
          style: AppTextStyles.caption.copyWith(color: Colors.white54),
        ),
      ],
    );
  }
}
