import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/stats_model.dart';
import '../../models/user_model.dart';
import '../../services/profile_service_stats.dart';
import '../../widgets/profile_content.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return const Center(child: Text('User not found'));
          }

          final user = UserModel.fromFirestore(userSnapshot.data!);

          return FutureBuilder<ProfileStats>(
            future: ProfileStatsService.fetchStats(userId),
            builder: (context, statsSnapshot) {
              if (statsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!statsSnapshot.hasData) {
                return const Center(child: Text('Failed to load stats'));
              }

              final stats = statsSnapshot.data!;

              return ProfileContent(
                user: user,
                stats: stats,
              );
            },
          );
        },
      ),
    );
  }
}
