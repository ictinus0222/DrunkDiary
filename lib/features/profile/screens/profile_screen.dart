import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../app/app_theme.dart';
import '../repositories/profile_repository.dart';
import '../models/profile_data_model.dart';
import '../widgets/user_profile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final repository = ProfileRepository();
    
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile',
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: customColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.settings, color: customColors.textMuted),
              onPressed: () {
                final user = FirebaseAuth.instance.currentUser;
                final adminEmails = [
                  'akhilsharma.ptk22@gmail.com',
                  'sharmakhil1704@gmail.com',
                ];

                if (user != null && adminEmails.contains(user.email)) {
                  Navigator.pushNamed(context, '/adminSettings');
                } else {
                  // Show generic settings or do nothing
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Settings coming soon!', style: TextStyle(color: colorScheme.onSurface))),
                  );
                }
              },
            ),
          ),
        ],
      ),
      body: FutureBuilder<ProfileDataModel>(
        future: repository.fetchUserProfile(userId),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: colorScheme.primary));
          }
          // Error state
          if (!snapshot.hasData) {
            return Center(child: Text('Failed to load profile', style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface)));
          }
          // Success state
          final profile = snapshot.data!;
          // Pass clean data to UserProfileContent()
          return UserProfile(
            userModel: profile.userData,
            userStats: profile.stats,
          );
        },
      ),
    );
  } // ☑️
}
