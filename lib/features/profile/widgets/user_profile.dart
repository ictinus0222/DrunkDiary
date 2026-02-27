import 'package:drunk_diary/features/profile/widgets/profile_content.dart';
import 'package:flutter/material.dart';

import '../models/stats_model.dart';
import '../models/user_model.dart';

class UserProfile extends StatefulWidget {
  final UserModel userModel;
  final ProfileStatsModel userStats;

  const UserProfile({
    super.key,
    required this.userModel,
    required this.userStats,
  });

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  @override
  void initState() {
    super.initState();
  } // ☑️

  @override
  Widget build(BuildContext context) {
    return ProfileContent(
      userModel: widget.userModel,
      userStats: widget.userStats,
      footer: [
        const SizedBox(height: 16),
        Text(
          'On DrunkDiary since ${widget.userModel.createdAt.month}/${widget.userModel.createdAt.year}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  } // ☑️
}
