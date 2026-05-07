import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:feedback/feedback.dart';
import '../../../app/app_theme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/services/google_auth_service.dart';
import '../models/profile_data_model.dart';
import '../providers/profile_providers.dart';
import '../widgets/delete_account_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileDataProvider);
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Center(
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: customColors.cardBackground,
                shape: BoxShape.circle,
                border: Border.all(color: customColors.borderDark),
              ),
              child: IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
        title: Text(
          'Settings',
          style: AppTextStyles.appBarTitle.copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: _buildBody(context, ref, profileAsync),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, AsyncValue<ProfileDataModel?> profileAsync) {
    final profile = profileAsync.value;
    
    // Only show full-screen loader on initial load (when there is no value yet)
    if (profile == null && profileAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (profile == null && profileAsync.hasError) {
      return Center(child: Text('Error: ${profileAsync.error}'));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.xxl),
        
        // 🛡️ ACCOUNT SECTION
        _SectionHeader(title: 'ACCOUNT'),
        _SettingSwitchTile(
          icon: Icons.lock_outline,
          title: 'Private Profile',
          subtitle: 'Hide your logs from the community feed.',
          value: profile?.userData.isPrivate ?? false,
          onChanged: (val) => _togglePrivacy(context, ref, profile),
        ),

        const SizedBox(height: AppSpacing.xxl),

        // 🆘 SUPPORT SECTION
        _SectionHeader(title: 'SUPPORT'),
        _SettingTile(
          icon: Icons.bug_report_outlined,
          title: 'Send Feedback',
          onTap: () => BetterFeedback.of(context).show((feedback) async {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Thank you for your feedback!')),
            );
          }),
        ),
        _SettingTile(
          icon: Icons.mail_outline,
          title: 'Submit a Ticket',
          onTap: () => _launchURL('mailto:akhil@drunkdiary.com'),
        ),
        _SettingTile(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          onTap: () => _launchURL('https://www.drunkdiary.com/privacy'),
        ),
        _SettingTile(
          icon: Icons.delete_outline,
          title: 'Delete Account',
          onTap: () => _showDeleteConfirmation(context),
        ),

        const SizedBox(height: AppSpacing.hero),

        // 🚪 SIGN OUT
        Center(
          child: TextButton(
            onPressed: () => _showLogoutConfirmation(context),
            child: Text(
              'Sign Out',
              style: AppTextStyles.body.copyWith(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: AppSpacing.hero),
      ],
    );
  }

  Future<void> _togglePrivacy(BuildContext context, WidgetRef ref, dynamic profile) async {
    if (profile == null) return;
    final currentStatus = profile.userData.isPrivate;
    await ref.read(profileRepositoryProvider).updatePrivacySetting(
      profile.userData.id, 
      !currentStatus,
    );
    ref.invalidate(profileDataProvider);
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const DeleteAccountDialog(),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sign Out', style: AppTextStyles.subtitle),
        content: const Text('Are you sure you want to sign out?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              // 1. Close dialog
              Navigator.pop(context);
              
              // 2. Perform sign-out
              await signOutGoogle();
              
              // 3. Clear the entire navigation stack and go back to AuthGate
              // This ensures the user lands on the LoginScreen immediately.
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/', // Go back to the root (AuthGate)
                  (route) => false,
                );
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md, left: 4),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          color: Colors.amber.withValues(alpha: 0.7),
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: customColors.cardBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(title, style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: subtitle != null 
            ? Text(subtitle!, style: AppTextStyles.caption.copyWith(color: customColors.textMuted)) 
            : null,
        trailing: Icon(Icons.chevron_right, color: Colors.amber.withValues(alpha: 0.3), size: 20),
        onTap: onTap,
      ),
    );
  }
}

class _SettingSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingSwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: customColors.cardBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(title, style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: subtitle != null 
            ? Text(subtitle!, style: AppTextStyles.caption.copyWith(color: customColors.textMuted)) 
            : null,
        value: value,
        onChanged: onChanged,
        activeColor: Colors.amber,
        activeTrackColor: Colors.amber.withValues(alpha: 0.3),
      ),
    );
  }
}


