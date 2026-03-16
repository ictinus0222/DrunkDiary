import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../app/app_theme.dart';
import '../widgets/user_profile.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_providers.dart';
import '../../../core/widgets/app_shimmer.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileDataProvider);
    
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
      body: profileAsync.when(
        loading: () => const _ProfileLoadingSkeleton(),
        error: (err, stack) => Center(child: Text('Failed to load profile', style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface))),
        data: (profile) {
          if (profile == null) return const Center(child: Text('No profile found'));
          // Pass clean data to UserProfileContent()
          return UserProfile(
            userModel: profile.userData,
            userStats: profile.stats,
          );
        },
      ),
    );
  }
}
/* ----------------------------- SKELETONS ----------------------------- */

class _ProfileLoadingSkeleton extends StatelessWidget {
  const _ProfileLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(
        children: [
          _ProfileHeaderSkeleton(),
          SizedBox(height: 24),
          _ProfileStatsSkeleton(),
          SizedBox(height: 32),
          _ProfileSectionSkeleton(title: 'YOUR SHELF'),
          SizedBox(height: 32),
          _ProfileSectionSkeleton(title: 'RECENT ACTIVITY'),
        ],
      ),
    );
  }
}

class _ProfileHeaderSkeleton extends StatelessWidget {
  const _ProfileHeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 24),
      child: Column(
        children: [
          AppShimmer.circular(size: 80),
          const SizedBox(height: 16),
          AppShimmer(width: 150, height: 24),
          const SizedBox(height: 8),
          AppShimmer(width: 100, height: 16),
        ],
      ),
    );
  }
}

class _ProfileStatsSkeleton extends StatelessWidget {
  const _ProfileStatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 21),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItemSkeleton(),
          _StatItemSkeleton(),
          _StatItemSkeleton(),
        ],
      ),
    );
  }
}

class _StatItemSkeleton extends StatelessWidget {
  const _StatItemSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AppShimmer(width: 40, height: 24),
        SizedBox(height: 8),
        AppShimmer(width: 60, height: 12),
      ],
    );
  }
}

class _ProfileSectionSkeleton extends StatelessWidget {
  final String title;
  const _ProfileSectionSkeleton({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 21),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 16),
          AppShimmer(
            height: 120,
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      ),
    );
  }
}
