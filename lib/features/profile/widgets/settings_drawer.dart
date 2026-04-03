import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../app/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/services/google_auth_service.dart';
import '../providers/profile_providers.dart';

class SettingsDrawer extends ConsumerWidget {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileDataProvider);
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // 🔹 Drawer Header
            profileAsync.when(
              data: (profile) => Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: customColors.cardBackground,
                      backgroundImage: profile?.userData.photoUrl != null
                          ? NetworkImage(profile!.userData.photoUrl!)
                          : null,
                      child: profile?.userData.photoUrl == null
                          ? Icon(Icons.person, size: 40, color: customColors.textMuted)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      profile?.userData.displayName ?? 'User',
                      style: AppTextStyles.subtitle,
                    ),
                    Text(
                      profile?.userData.username ?? '',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
              error: (_, __) => const SizedBox(height: 100),
            ),

            const Divider(indent: 24, endIndent: 24),

            // 🔹 Admin Settings (Conditional)
            _buildAdminTile(context),

            // 🔹 Spacer to push Logout to bottom
            const Spacer(),

            // 🔹 Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ListTile(
                leading: Icon(Icons.logout, color: customColors.error),
                title: Text(
                  'Logout',
                  style: AppTextStyles.body.copyWith(color: customColors.error),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () => _showLogoutConfirmation(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminTile(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final adminEmails = [
      'akhilsharma.ptk22@gmail.com',
      'sharmakhil1704@gmail.com',
    ];

    if (user != null && adminEmails.contains(user.email)) {
      return ListTile(
        leading: const Icon(Icons.admin_panel_settings_outlined),
        title: Text('Admin Settings', style: AppTextStyles.body),
        onTap: () {
          Navigator.pop(context); // Close drawer
          Navigator.pushNamed(context, '/adminSettings');
        },
      );
    }
    return const SizedBox.shrink();
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('Logout', style: AppTextStyles.subtitle),
        content: Text(
          'Are you sure you want to logout from DrunkDiary?',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close drawer
              await signOutGoogle();
            },
            child: Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
