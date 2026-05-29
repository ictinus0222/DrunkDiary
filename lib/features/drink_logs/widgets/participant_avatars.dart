import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/app_theme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../profile/models/user_model.dart';
import '../../profile/providers/profile_providers.dart';
import '../../profile/screens/profile_screen.dart';
import '../models/drink_model_dto.dart';
import '../providers/drink_logs_provider.dart';
import '../../../core/providers/common_providers.dart';

class ParticipantAvatars extends ConsumerWidget {
  final DrinkLogModel log;
  final double radius;

  const ParticipantAvatars({
    super.key,
    required this.log,
    this.radius = 12.0,
  });

  void _showSharedWithBottomSheet(BuildContext context, WidgetRef ref, List<UserModel> participants) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final currentUserId = ref.read(userIdProvider);
    final profileAsync = ref.read(profileDataProvider);
    final currentUser = profileAsync.value?.userData;

    showModalBottomSheet(
      context: context,
      backgroundColor: customColors.deepCardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: customColors.borderDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Shared With',
                  style: AppTextStyles.section.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(color: Colors.white10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: participants.length,
                  itemBuilder: (context, index) {
                    final participant = participants[index];
                    final isSelf = participant.id == currentUserId;
                    final isFriend = currentUser?.friends.contains(participant.id) ?? false;
                    final isOutgoingPending = currentUser?.pendingOutgoingRequests.contains(participant.id) ?? false;

                    return ListTile(
                      leading: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProfileScreen(userId: participant.id),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: customColors.borderDark,
                          backgroundImage: participant.photoUrl != null
                              ? CachedNetworkImageProvider(participant.photoUrl!)
                              : null,
                          child: participant.photoUrl == null
                              ? const Icon(Icons.person, color: Colors.white24, size: 20)
                              : null,
                        ),
                      ),
                      title: Text(
                        participant.displayName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '@${participant.username}',
                        style: TextStyle(color: customColors.textMuted, fontSize: 12),
                      ),
                      trailing: _buildFriendshipButton(
                        context,
                        ref,
                        isSelf: isSelf,
                        isFriend: isFriend,
                        isOutgoingPending: isOutgoingPending,
                        participant: participant,
                        currentUser: currentUser,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFriendshipButton(
    BuildContext context,
    WidgetRef ref, {
    required bool isSelf,
    required bool isFriend,
    required bool isOutgoingPending,
    required UserModel participant,
    UserModel? currentUser,
  }) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;

    if (isSelf) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('You', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
      );
    }

    if (isFriend) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, color: Colors.green, size: 16),
          const SizedBox(width: 4),
          Text(
            'Friends ✓',
            style: TextStyle(color: customColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      );
    }

    if (isOutgoingPending) {
      return Text(
        'Request Sent',
        style: TextStyle(color: customColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
      );
    }

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber.withOpacity(0.1),
        foregroundColor: Colors.amber,
        side: const BorderSide(color: Colors.amber, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () async {
        if (currentUser == null) return;
        try {
          await ref.read(friendshipRepositoryProvider).sendFriendRequest(
                fromUserId: currentUser.id,
                fromUsername: currentUser.username,
                fromPhotoUrl: currentUser.photoUrl,
                toUserId: participant.id,
              );
          // Invalidate profile data to refresh pending requests state
          ref.invalidate(profileDataProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Friend request sent to @${participant.username}')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not send request: $e')),
            );
          }
        }
      },
      icon: const Icon(Icons.add, size: 14),
      label: const Text('Add Friend', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participantsAsync = ref.watch(logParticipantsProvider(log.id));

    return ExcludeSemantics(
      child: participantsAsync.when(
        loading: () => _buildAvatarPlaceholder(),
        error: (_, __) => _buildAvatarPlaceholder(),
        data: (participants) {
          if (participants.isEmpty) {
            return _buildAvatarPlaceholder();
          }

          // Render overlapping avatars
          final stackWidth = (radius * 2) + (participants.length - 1) * (radius * 1.2) + 4;
          return GestureDetector(
            onTap: () => _showSharedWithBottomSheet(context, ref, participants),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              height: radius * 2 + 4,
              width: stackWidth,
              child: Stack(
                clipBehavior: Clip.none,
                children: List.generate(participants.length, (index) {
                  final participant = participants[index];
                  return Positioned(
                    left: index * (radius * 1.2),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: CircleAvatar(
                        radius: radius,
                        backgroundImage: participant.photoUrl != null
                            ? CachedNetworkImageProvider(participant.photoUrl!)
                            : null,
                        child: participant.photoUrl == null
                            ? Icon(Icons.person, size: radius * 1.2, color: Colors.white70)
                            : null,
                      ),
                    ),
                  );
                }),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundImage: log.userPhotoUrl != null
            ? CachedNetworkImageProvider(log.userPhotoUrl!)
            : null,
        child: log.userPhotoUrl == null
            ? Icon(Icons.person, size: radius * 1.2, color: Colors.white70)
            : null,
      ),
    );
  }
}
