import 'package:drunk_diary/features/profile/widgets/profile_content.dart';
import 'package:flutter/material.dart';

import '../models/stats_model.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';

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
  final UserRepository _userRepository = UserRepository();

  late bool isProfilePublic;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    isProfilePublic = widget.userModel.isProfilePublic; // Initialize with the current value in Firestore
  } // ☑️

  @override
  Widget build(BuildContext context) {
    return ProfileContent(

      userModel: widget.userModel,
      userStats: widget.userStats,

      footer: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Public Profile'),
          subtitle: const Text('Allow others to view your profile'),
          value: isProfilePublic,
          onChanged: isUpdating ? null : _toggleProfileVisibility,
        ),

        const SizedBox(height: 8),

        // Helper Text
        Text(
          isProfilePublic
              ? 'Your profile is visible to other users.'
              : 'Your profile is private. Only you can view it.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),

        const SizedBox(height: 16),

        Text(
          'On DrunkDiary since ${widget.userModel.createdAt.month}/${widget.userModel.createdAt.year}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  } // ☑️

  // _toggleProfileVisibility()
  Future<void> _toggleProfileVisibility(bool value) async {
    setState(() {
      isProfilePublic = value;
      isUpdating = true;
    });

    try {
      await _userRepository.updateProfileVisibility(
        userId: widget.userModel.id,
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
  } // ☑️

}
