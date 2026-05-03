import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../app/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../drink_logs/models/drink_model_dto.dart';
import '../../drink_logs/providers/drink_logs_provider.dart';
import '../../drink_logs/widgets/day_section.dart';
import '../providers/profile_providers.dart';
import '../widgets/settings_drawer.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileDataProvider);
    final logsAsync = ref.watch(drinkLogsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      endDrawer: const SettingsDrawer(),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (profile) {
          if (profile == null) return const Center(child: Text('No profile found'));

          return logsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (allLogs) {
              // Calculate unique days logged
              final uniqueDays = allLogs
                  .map((log) => DateTime(
                        log.createdAt.year,
                        log.createdAt.month,
                        log.createdAt.day,
                      ))
                  .toSet()
                  .length;

              final groupedLogs = _groupLogsByDate(allLogs);

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  // 1. Hero Section
                  SliverToBoxAdapter(
                    child: _ProfileHeader(
                      profile: profile.userData,
                      uniqueDays: uniqueDays,
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

                  // 2. Tabs Section (Simplified)
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
                          Container(
                            height: 2,
                            width: 40,
                            color: Colors.amber,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

                  // 3. Activity Section (Diary Mirror)
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
            },
          );
        },
      ),
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
  final dynamic profile; // Using dynamic to avoid strict UserModel dependency if it varies
  final int uniqueDays;

  const _ProfileHeader({
    required this.profile,
    required this.uniqueDays,
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
                      placeholder: (_, __) => const AppShimmer(),
                      errorWidget: (_, __, ___) => const Icon(Icons.image, color: Colors.white12, size: 48),
                    )
                  : const Center(child: Icon(Icons.image, color: Colors.white12, size: 48)),
            ),

            // Settings Icon
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
            ),

            // Overlapping Avatar
            Positioned(
              bottom: -40,
              left: 16,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black,
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
              OutlinedButton(
                onPressed: () {
                  // TODO: edit profile later
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: customColors.borderDark),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Edit"),
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
              style: AppTextStyles.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

        const SizedBox(height: 16),

        // ── Stats ─────────────────────────────────────────────────────────────
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
}
