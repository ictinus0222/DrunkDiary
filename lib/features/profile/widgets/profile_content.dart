import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../app/app_theme.dart';
import '../../../core/constants/reaction_config.dart';
import '../models/stats_model.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/user_model.dart';

class ProfileContent extends StatelessWidget {
  final UserModel userModel;
  final ProfileStatsModel userStats;
  final List<Widget> footer;

  const ProfileContent({
    super.key,
    required this.userModel,
    required this.userStats,
    this.footer = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Profile Card
          _buildProfileCard(context),

          const SizedBox(height: AppSpacing.hero),

          // Public Shelf Section
          _buildPublicShelf(context),

          const SizedBox(height: AppSpacing.hero),

          // Recent Activity Section
          _buildRecentActivity(context),

          if (footer.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            ...footer,
          ]
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: customColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: colorScheme.primary,
                backgroundImage: userModel.photoUrl != null
                    ? NetworkImage(userModel.photoUrl!)
                    : null,
                child: userModel.photoUrl == null
                    ? Icon(Icons.person, size: 32, color: colorScheme.onPrimary)
                    : null,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userModel.displayName,
                      style: AppTextStyles.title.copyWith(
                            color: colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'My Personal Shelf',
                      style: AppTextStyles.body.copyWith(
                        color: customColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatItem(
                icon: Icons.wine_bar,
                value: userStats.totalLogs.toString(),
                label: 'Drinks Tried',
              ),
              _StatItem(
                icon: Icons.trending_up,
                value: userStats.favoriteType ?? '—',
                label: 'Favorite Type',
              ),
              _StatItem(
                icon: Icons.star,
                value: userStats.topRatedAlcohol != null &&
                        userStats.topRatedAlcohol!.length > 10
                    ? '${userStats.topRatedAlcohol!.substring(0, 10)}...'
                    : (userStats.topRatedAlcohol ?? '—'),
                label: 'Top Rated',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPublicShelf(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Collection',
              style: AppTextStyles.title.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              '${userStats.recentAlcohols.length} entries',
              style: AppTextStyles.body.copyWith(
                color: customColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (userStats.recentAlcohols.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: Center(
              child: Text(
                "Shelf is empty",
                style: AppTextStyles.body.copyWith(color: customColors.textMuted),
              ),
            ),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: userStats.recentAlcohols.length,
              separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) {
                final alcohol = userStats.recentAlcohols[index];
                return Container(
                  width: 100,
                  decoration: BoxDecoration(
                    color: customColors.cardBackground,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: alcohol.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: alcohol.imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Icon(
                            Icons.broken_image,
                            color: customColors.textMuted,
                          ),
                        )
                      : Icon(Icons.wine_bar,
                          color: customColors.textMuted, size: 40),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: AppTextStyles.title.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (userStats.recentLogs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: Center(
              child: Text(
                "No recent activity",
                style: AppTextStyles.body.copyWith(color: customColors.textMuted),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: userStats.recentLogs.length,
            itemBuilder: (context, index) {
              final log = userStats.recentLogs[index];
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: customColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: customColors.deepCardBackground,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusCompact),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: log.photoUrl != null
                          ? CachedNetworkImage(
                              imageUrl: log.photoUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Icon(
                                Icons.broken_image,
                                color: customColors.textMuted,
                              ),
                            )
                          : Icon(Icons.wine_bar, color: colorScheme.primary),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.alcoholName,
                            style: AppTextStyles.body.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            log.alcoholType,
                            style: AppTextStyles.caption.copyWith(
                              color: customColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (log.rating != null)
                      Row(
                        children: [
                          Icon(Icons.star, color: colorScheme.primary, size: 18),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            log.rating!.toStringAsFixed(1).replaceAll('.0', ''),
                            style: AppTextStyles.body.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    else if (log.reaction != null)
                      Icon(
                        ReactionConfig.getIcon(log.reaction!),
                        color: ReactionConfig.getColor(log.reaction!),
                        size: 18,
                      )
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary, size: 28),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: customColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
