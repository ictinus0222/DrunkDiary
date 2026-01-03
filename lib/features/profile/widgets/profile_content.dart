import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../models/stats_model.dart';

class ProfileContent extends StatelessWidget {
  final UserModel userModel;
  final ProfileStatsModel userStats;

  /// Extra widgets rendered at the bottom (owner-only)
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // Header
          Row(
            children: [

              CircleAvatar(
                radius: 32,
                backgroundImage:
                userModel.photoUrl != null ? NetworkImage(userModel.photoUrl!) : null,
                child: userModel.photoUrl == null
                    ? const Icon(Icons.person, size: 32)
                    : null,
              ),

              const SizedBox(width: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    userModel.displayName,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    '@${userModel.username}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),

                ],
              ),

            ],

          ),

          const SizedBox(height: 12),

          // Bio
          if (userModel.bio != null && userModel.bio!.isNotEmpty)
            Text(
              userModel.bio!,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 14,
                height: 1.4,
              ),
            )
          else
            Text(
              'No bio yet',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),

          const SizedBox(height: 24),

          // Stats Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [

                _StatItem(
                  label: 'Drinks',
                  value: userStats.totalLogs.toString(),
                ),

                _StatItem(
                  label: 'Bottles',
                  value: userStats.uniqueBottles.toString(),
                ),

                _StatItem(
                  label: 'Avg',
                  value: userStats.averageRating == 0
                      ? '–'
                      : userStats.averageRating.toStringAsFixed(1),
                ),

              ],
            ),
          ),

          const SizedBox(height: 16),

          // add footer according to profile
          ...footer,
        ],

      ),
    );
  } // ☑️
}
class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 0.5,
            color: Colors.grey.shade600,
          ),
        ),

      ],
    );
  } // ☑️
}
