import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../repositories/profile_repository.dart';
import '../models/profile_data_model.dart';
import '../widgets/user_profile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final repository = ProfileRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: FutureBuilder<ProfileDataModel>(
        future: repository.fetchUserProfile(userId),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Error state
          if (!snapshot.hasData) {
            return const Center(child: Text('Failed to load profile'));
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
