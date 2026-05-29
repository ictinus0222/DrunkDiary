import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../providers/profile_providers.dart';
import '../../../core/providers/common_providers.dart';
import '../../../core/theme/app_colors.dart';
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

            // Action Affordance
            _buildAction(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildAction(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(userIdProvider);
    if (currentUserId == null || currentUserId == user.id) return const SizedBox.shrink();

    final profileAsync = ref.watch(profileDataProvider);
    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();

        final currentUser = profile.userData;
        
        // Local copies with guaranteed non-nullability
        final List<String> friends = currentUser.friends;
        final List<String> pendingOut = currentUser.pendingOutgoingRequests;
        final List<String> pendingIn = currentUser.pendingIncomingRequests;
        final List<String> blocked = currentUser.blockedUsers;
        
        // Determine relationship
        if (friends.contains(user.id)) {
          return _buildRelationshipBadge(Icons.check_circle_rounded, 'Friends', AppColors.amber);
        } else if (pendingOut.contains(user.id)) {
          return _buildRelationshipBadge(Icons.hourglass_bottom_rounded, 'Sent', Colors.white38);
        } else if (pendingIn.contains(user.id)) {
          return _buildActionButton(
            Icons.person_add_rounded,
            AppColors.amber,
            () => _handleAccept(context, ref, currentUserId),
          );
        } else if (blocked.contains(user.id)) {
          return _buildRelationshipBadge(Icons.block_rounded, 'Blocked', Colors.white24);
        } else {
          return _buildActionButton(
            Icons.person_add_rounded,
            Colors.white70,
            () => _handleSendRequest(context, ref, currentUser),
          );
        }
      },
      loading: () => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      error: (err, stack) {
        debugPrint('Error in UserSearchTile buildAction: $err');
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildRelationshipBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onPressed) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: color),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  Future<void> _handleSendRequest(BuildContext context, WidgetRef ref, UserModel currentUser) async {
    try {
      await ref.read(friendshipRepositoryProvider).sendFriendRequest(
            fromUserId: currentUser.id,
            fromUsername: currentUser.displayName,
            fromPhotoUrl: currentUser.photoUrl,
            toUserId: user.id,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Friend request sent to ${user.displayName}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send request: $e')),
        );
      }
    }
  }

  Future<void> _handleAccept(BuildContext context, WidgetRef ref, String currentUserId) async {
    try {
      await ref.read(friendshipRepositoryProvider).acceptFriendRequest(currentUserId, user.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Accepted ${user.displayName}\'s friend request')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept: $e')),
        );
      }
    }
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
                memCacheWidth: 150,
                placeholder: (context, url) => Container(color: Colors.white12),
                errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.white24),
              )
            : const Icon(Icons.person, color: Colors.white24),
      ),
    );
  }

}
