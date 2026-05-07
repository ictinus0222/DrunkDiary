import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class UserSearchTile extends ConsumerWidget {
  final UserModel user;
  final VoidCallback onTap;

  const UserSearchTile({
    super.key,
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.md,
        ),
        child: Row(
          children: [
            // Avatar
            _buildAvatar(),
            const SizedBox(width: AppSpacing.md),
            
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.displayName,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.isPrivate) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 14,
                          color: Colors.white38,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    '@${user.username}',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),

            // Action Affordance (Quick-Add for future)
            if (user.friendState == FriendState.none)
              _buildAddFriendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: ClipOval(
        child: user.photoUrl != null
            ? CachedNetworkImage(
                imageUrl: user.photoUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.white12),
                errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.white24),
              )
            : const Icon(Icons.person, color: Colors.white24),
      ),
    );
  }

  Widget _buildAddFriendButton() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person_add_rounded,
        size: 18,
        color: Colors.white70,
      ),
    );
  }
}
