import 'package:drunk_diary/features/profile/widgets/profile_content.dart';
import 'package:flutter/material.dart';

import '../models/stats_model.dart';
import '../models/user_model.dart';

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
    return ProfileContent(

      userModel: userModel,
      userStats: userStats,

      footer: [

        const SizedBox(height: 16),

        Text(
          'On DrunkDiary since ${userModel.createdAt.month}/${userModel.createdAt.year}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),

      ],
    );
  }
}

