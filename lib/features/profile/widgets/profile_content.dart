import 'package:flutter/material.dart';

import '../models/stats_model.dart';
import '../models/user_model.dart';
import '../repositories/profile_repository.dart';

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
      // Rollback on failure (safe fallback)
      setState(() {
        isProfilePublic = !value;
      });
    } finally {
      setState(() {
        isUpdating = false;
      });
    }
  }

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
                widget.user.photoUrl != null
                    ? NetworkImage(widget.user.photoUrl!)
                    : null,
                child: widget.user.photoUrl == null
                    ? const Icon(Icons.person, size: 32)
                    : null,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.displayName,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${widget.user.username}',
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

          if (widget.user.bio == null || widget.user.bio!.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No bio yet',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                  height: 1.4,
                ),
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
                  value: widget.stats.totalLogs.toString(),
                ),
                _StatItem(
                  label: 'Bottles',
                  value: widget.stats.uniqueBottles.toString(),
                ),
                _StatItem(
                  label: 'Avg',
                  value: widget.stats.averageRating == 0
                      ? '–'
                      : widget.stats.averageRating.toStringAsFixed(1),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 🔐 Public / Private Toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Public Profile'),
            subtitle: const Text(
              'Allow others to view your profile',
            ),
            value: isProfilePublic,
            onChanged: isUpdating ? null : _toggleProfileVisibility,
          ),

          const SizedBox(height: 8),

          Text(
            isProfilePublic
                ? 'Your profile is visible via a shareable link.'
                : 'Your profile is private. Only you can view it.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'On DrunkDiary since ${widget.user.createdAt.month}/${widget.user.createdAt.year}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
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
  }
}
