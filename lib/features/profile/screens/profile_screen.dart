import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../drink_logs/models/drink_model_dto.dart';
import '../../drink_logs/providers/drink_logs_provider.dart';
import '../../drink_logs/widgets/day_section.dart';
import '../providers/profile_providers.dart';
import '../../../app/app_routes.dart';
import '../../../core/providers/common_providers.dart';
import '../widgets/edit_profile_sheet.dart';

class ProfileScreen extends ConsumerWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(userIdProvider);
    final isMe = userId == null || userId == currentUserId;
    final effectiveUserId = userId ?? currentUserId;

    if (effectiveUserId == null) return const Center(child: Text('Not logged in'));

    final profileAsync = isMe 
        ? ref.watch(profileDataProvider) 
        : ref.watch(otherProfileDataProvider(effectiveUserId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: profileAsync.when(
        skipLoadingOnRefresh: true,
        loading: () => profileAsync.hasValue 
            ? _buildProfileData(context, ref, profileAsync.value, isMe)
            : const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (profile) => _buildProfileData(context, ref, profile, isMe),
      ),
    );
  }

  Widget _buildProfileData(BuildContext context, WidgetRef ref, dynamic profile, bool isMe) {
    if (profile == null) return const Center(child: Text('No profile found'));

    final userData = profile.userData;
    final isPrivate = userData.isPrivate;
    final showFullProfile = isMe || !isPrivate;

    if (!showFullProfile) {
      return _buildPrivateProfileView(context, userData);
    }

    return _buildFullProfile(context, ref, profile, isMe);
  }

  Widget _buildPrivateProfileView(BuildContext context, dynamic userData) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _ProfileHeader(
            profile: userData,
            uniqueDays: 0, // Hide stats for private profiles
            isMe: false,
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.white24),
              const SizedBox(height: 16),
              Text(
                'This profile is private',
                style: AppTextStyles.subtitle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This user has hidden their activity and diary.',
                style: AppTextStyles.body.copyWith(color: Colors.white54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFullProfile(BuildContext context, WidgetRef ref, dynamic profile, bool isMe) {
    final effectiveUserId = userId ?? ref.watch(userIdProvider);
    if (effectiveUserId == null) return const Center(child: Text('User ID missing'));

    final logsAsync = ref.watch(userDrinkLogsProvider(effectiveUserId));
    
    return logsAsync.when(
      skipLoadingOnRefresh: true,
      loading: () => logsAsync.hasValue 
          ? _buildProfileContent(context, ref, profile.userData, 
              logsAsync.value!.map((log) => DateTime(log.createdAt.year, log.createdAt.month, log.createdAt.day)).toSet().length,
              _groupLogsByDate(logsAsync.value!), isMe)
          : const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (allLogs) {
        final uniqueDays = allLogs.map((log) => DateTime(log.createdAt.year, log.createdAt.month, log.createdAt.day)).toSet().length;
        final groupedLogs = _groupLogsByDate(allLogs);
        return _buildProfileContent(context, ref, profile.userData, uniqueDays, groupedLogs, isMe);
      },
    );
  }

  Widget _buildProfileContent(
    BuildContext context, 
    WidgetRef ref, 
    dynamic userData, 
    int uniqueDays, 
    List<MapEntry<DateTime, List<DrinkLogModel>>> groupedLogs,
    bool isMe,
  ) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(
          child: _ProfileHeader(
            profile: userData,
            uniqueDays: uniqueDays,
            isMe: isMe,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACTIVITY',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(height: 8),
                Container(height: 2, width: 40, color: Colors.amber),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final entry = groupedLogs[index];
              return DayActivityCard(
                date: entry.key,
                logs: entry.value,
                showUser: false,
              );
            },
            childCount: groupedLogs.length,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.hero)),
      ],
    );
  }

  // ── Grouping Logic (Mirror of DiaryScreen) ──────────────────────────────────

  List<MapEntry<DateTime, List<DrinkLogModel>>> _groupLogsByDate(List<DrinkLogModel> logs) {
    final Map<DateTime, List<DrinkLogModel>> grouped = {};

    for (final log in logs) {
      final date = log.createdAt.toLocal();
      final dayStart = DateTime(date.year, date.month, date.day);
      if (!grouped.containsKey(dayStart)) {
        grouped[dayStart] = [];
      }
      grouped[dayStart]!.add(log);
    }
    
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
      
    return sortedEntries;
  }
}

class _ProfileHeader extends StatelessWidget {
  final dynamic profile;
  final int uniqueDays;
  final bool isMe;

  const _ProfileHeader({
    required this.profile,
    required this.uniqueDays,
    this.isMe = true,
  });

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Cover Image + Avatar Stack ───────────────────────────────────────
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Cover Image
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: customColors.cardBackground,
              ),
              child: profile.coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: profile.coverUrl!,
                      fit: BoxFit.cover,
                      fadeInDuration: Duration.zero,
                      placeholder: (_, __) => Container(color: Colors.white10),
                      errorWidget: (_, __, ___) => const Icon(Icons.image, color: Colors.white12, size: 48),
                    )
                  : const Center(child: Icon(Icons.image, color: Colors.white12, size: 48)),
            ),

            // Settings Icon
            if (isMe)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                  child: IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () => Navigator.of(context, rootNavigator: true).pushNamed(AppRoutes.settings),
                  ),
                ),
              )
            else
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),

            // Overlapping Avatar
            Positioned(
              bottom: -40,
              left: 16,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.amber,
                  backgroundImage: profile.photoUrl != null
                      ? CachedNetworkImageProvider(profile.photoUrl!)
                      : null,
                  child: profile.photoUrl == null
                      ? const Icon(Icons.person, size: 40, color: Colors.black)
                      : null,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 48),

        // ── Name + Edit Row ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  profile.displayName,
                  style: AppTextStyles.subtitle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
              if (isMe)
                Row(
                  children: [
                    if (profile.instagram != null && profile.instagram!.isNotEmpty) ...[
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.alternate_email, color: Colors.amber, size: 18),
                          onPressed: () => _launchInstagram(context, profile.instagram!),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    OutlinedButton(
                      onPressed: () => EditProfileSheet.show(context, profile),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: customColors.borderDark),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Edit"),
                    ),
                  ],
                )
              else if (profile.instagram != null && profile.instagram!.isNotEmpty)
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.alternate_email, color: Colors.amber, size: 18),
                    onPressed: () => _launchInstagram(context, profile.instagram!),
                  ),
                ),
            ],
          ),
        ),

        // ── Username ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            "@${profile.username}",
            style: AppTextStyles.body.copyWith(
              color: customColors.textMuted,
            ),
          ),
        ),

        // ── Bio (Optional) ────────────────────────────────────────────────────
        if (profile.bio != null && profile.bio!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 12, AppSpacing.lg, 0),
            child: Text(
              profile.bio!,
              style: AppTextStyles.body.copyWith(
                height: 1.4,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),

        const SizedBox(height: 16),

        // ── Stats ─────────────────────────────────────────────────────────────
        if (uniqueDays > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              "$uniqueDays DAYS LOGGED",
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.white70,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _launchInstagram(BuildContext context, String handle) async {
    final cleanHandle = handle.replaceAll('@', '').trim();
    if (cleanHandle.isEmpty) return;
    
    final url = Uri.parse('https://www.instagram.com/$cleanHandle/');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open Instagram profile: $e')),
        );
      }
    }
  }
}
