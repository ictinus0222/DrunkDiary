import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../app/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/services/google_auth_service.dart';
import '../models/profile_data_model.dart';
import '../providers/profile_providers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
            _buildAdminTiles(context, ref, profileAsync.value),

            const Divider(indent: 24, endIndent: 24),

            // 🔹 Legal Tiles
            ListTile(
              leading: Icon(Icons.privacy_tip_outlined, color: customColors.textMuted),
              title: Text('Privacy Policy', style: AppTextStyles.body),
              onTap: () => _launchURL('https://www.drunkdiary.com/privacy'),
            ),
            ListTile(
              leading: Icon(Icons.child_care_outlined, color: customColors.textMuted),
              title: Text('Child Safety Policy', style: AppTextStyles.body),
              onTap: () => _launchURL('https://www.drunkdiary.com/child-safety'),
            ),

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

            // 🔹 Version Info
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'v${snapshot.data!.version}+${snapshot.data!.buildNumber}',
                      style: AppTextStyles.caption.copyWith(color: customColors.textMuted),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Widget _buildAdminTiles(BuildContext context, WidgetRef ref, ProfileDataModel? profile) {
    final user = FirebaseAuth.instance.currentUser;
    final adminEmails = [
      'akhilsharma.ptk22@gmail.com',
      'sharmakhil1704@gmail.com',
    ];

    final isAuthorized = (profile?.userData.role == 'admin') || 
                         (user != null && adminEmails.contains(user.email));

    if (!isAuthorized) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.add_business_outlined),
          title: Text('Admin Bottle Manager', style: AppTextStyles.body),
          onTap: () {
            Navigator.pop(context); // Close drawer
            Navigator.pushNamed(context, '/adminBottleManager');
          },
        ),
      ],
    );
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
