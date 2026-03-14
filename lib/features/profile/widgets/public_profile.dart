import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../models/stats_model.dart';
import '../models/user_model.dart';
import 'profile_content.dart';

class PublicProfile extends StatelessWidget {
  final UserModel userModel;
  final ProfileStatsModel userStats;

  const PublicProfile({
    super.key,
    required this.userModel,
    required this.userStats,
  });

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return ProfileContent(
      userModel: userModel,
      userStats: userStats,
      footer: [
        const SizedBox(height: 16),
        Text(
          'On DrunkDiary since ${userModel.createdAt.month}/${userModel.createdAt.year}',
          style: textTheme.bodySmall?.copyWith(
            color: customColors.textMuted,
          ),
        ),
      ],
    );
  }
}
