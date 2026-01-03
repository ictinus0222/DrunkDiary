import 'package:drunk_diary/features/profile/widgets/profile_base_content.dart';
import 'package:flutter/material.dart';

import '../models/stats_model.dart';
import '../models/user_model.dart';

class ProfilePublicContent extends StatelessWidget {
  final UserModel user;
  final ProfileStats stats;

  const ProfilePublicContent({
    super.key,
    required this.user,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileBaseContent(
      user: user,
      stats: stats,
      footer: const [],
    );
  }
}
