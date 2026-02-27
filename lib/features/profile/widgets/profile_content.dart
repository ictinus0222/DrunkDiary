import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/stats_model.dart';
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Profile Card
          _buildProfileCard(context),

          const SizedBox(height: 32),

          // Public Shelf Section
          _buildPublicShelf(),

          const SizedBox(height: 32),

          // Recent Activity Section
          _buildRecentActivity(),

          if (footer.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...footer,
          ]
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xff1C1C1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.amber,
                backgroundImage: userModel.photoUrl != null
                    ? NetworkImage(userModel.photoUrl!)
                    : null,
                child: userModel.photoUrl == null
                    ? const Icon(Icons.person, size: 32, color: Colors.black)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userModel.displayName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'My Personal Shelf',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
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

  Widget _buildPublicShelf() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Public Shelf',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '${userStats.recentAlcohols.length} entries',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (userStats.recentAlcohols.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                "Shelf is empty",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: userStats.recentAlcohols.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final alcohol = userStats.recentAlcohols[index];
                return Container(
                  width: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xff1C1C1E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: alcohol.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: alcohol.imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        )
                      : const Icon(Icons.wine_bar,
                          color: Colors.grey, size: 40),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        if (userStats.recentLogs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                "No recent activity",
                style: TextStyle(color: Colors.grey.shade600),
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
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xff1C1C1E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: log.photoUrl != null
                          ? CachedNetworkImage(
                              imageUrl: log.photoUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            )
                          : const Icon(Icons.wine_bar, color: Colors.amber),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.alcoholName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            log.alcoholType,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (log.rating != null)
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            log.rating!.toStringAsFixed(1).replaceAll('.0', ''),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      )
                    else if (log.isLiked != null)
                      Icon(
                        log.isLiked! ? Icons.thumb_up : Icons.thumb_down,
                        color: log.isLiked! ? Colors.green : Colors.red,
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
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.amber, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
