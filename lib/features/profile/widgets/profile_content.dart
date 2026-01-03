import 'package:drunk_diary/features/profile/widgets/profile_base_content.dart';
import 'package:flutter/material.dart';

import '../models/stats_model.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';

class ProfileContent extends StatefulWidget {
  final UserModel user;
  final ProfileStats stats;

  const ProfileContent({
    super.key,
    required this.user,
    required this.stats,
  });

  @override
  State<ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<ProfileContent> {
  final UserRepository _userRepository = UserRepository();

  late bool isProfilePublic;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    isProfilePublic = widget.user.isProfilePublic;
  }

  @override
  Widget build(BuildContext context) {
    return ProfileBaseContent(
      user: widget.user,
      stats: widget.stats,
      footer: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Public Profile'),
          subtitle: const Text('Allow others to view your profile'),
          value: isProfilePublic,
          onChanged: isUpdating ? null : _toggleProfileVisibility,
        ),
        const SizedBox(height: 8),
        Text(
          isProfilePublic
              ? 'Your profile is visible via a shareable link.'
              : 'Your profile is private. Only you can view it.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        Text(
          'On DrunkDiary since ${widget.user.createdAt.month}/${widget.user.createdAt.year}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
  Future<void> _toggleProfileVisibility(bool value) async {
    setState(() {
      isProfilePublic = value;
      isUpdating = true;
    });

    try {
      await _userRepository.updateProfileVisibility(
        userId: widget.user.id,
        isProfilePublic: value,
      );
    } catch (e) {
      // Rollback on failure
      setState(() {
        isProfilePublic = !value;
      });
    } finally {
      setState(() {
        isUpdating = false;
      });
    }
  }

}
