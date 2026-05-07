import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
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
    try {
      setState(() => errorMessage = 'Re-authenticating...');
      
      // We re-run the sign-in flow to get a fresh credential
      await signInWithGoogle(); 
      
      // After successful re-auth, retry deletion
      await _handleDelete();
    } catch (e) {
      setState(() {
        errorMessage = 'Re-authentication failed. Please try again.';
        isDeleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Delete Account?',
        style: AppTextStyles.subtitle.copyWith(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This action is permanent.',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Your profile, drink logs, diary entries, cheers, photos, and activity history will be permanently deleted and cannot be recovered.',
            style: AppTextStyles.body.copyWith(color: Colors.white70),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: isDeleting ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
        ),
        ElevatedButton(
          onPressed: isDeleting ? null : _handleDelete,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade900,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: isDeleting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Delete Permanently'),
        ),
      ],
    );
  }
}
