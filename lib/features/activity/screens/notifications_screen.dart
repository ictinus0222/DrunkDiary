import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';
import '../../profile/providers/profile_providers.dart';
import '../../profile/screens/profile_screen.dart';

import '../../../app/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../providers/notifications_provider.dart';
import '../models/notification_model.dart';
import '../screens/activity_detail_viewer.dart';
import '../../drink_logs/models/drink_model_dto.dart';
import '../../drink_logs/repositories/drink_log_repository.dart';
import '../../drink_logs/providers/drink_logs_provider.dart';
import '../../../core/providers/common_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final userId = ref.watch(userIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('NOTIFICATIONS', style: AppTextStyles.appBarTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () {
              if (userId != null) {
                ref.read(notificationRepositoryProvider).markAllAsRead(userId);
              }
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const _NotificationsLoadingSkeleton(),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const AppEmptyState(
              icon: Icons.notifications_none_outlined,
              title: 'No notifications yet',
              subtitle: 'When people cheer your sessions,\nyou\'ll see them here.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              return _NotificationItem(
                notification: notifications[index],
                userId: userId!,
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationItem extends ConsumerWidget {
  final NotificationModel notification;
  final String userId;

  const _NotificationItem({
    required this.notification,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    
    return InkWell(
      onTap: () {
        // Mark as read
        ref.read(notificationRepositoryProvider).markAsRead(userId, notification.id);
        
        if (notification.type == 'cheers') {
          _handleCheersTap(context, ref);
        } else {
          // Default: Navigate to Sender's Profile
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileScreen(userId: notification.senderId),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        color: notification.isRead 
            ? Colors.transparent 
            : Colors.amber.withOpacity(0.05),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Image
            CircleAvatar(
              radius: 24,
              backgroundColor: customColors.borderDark,
              backgroundImage: notification.senderProfileImage != null
                  ? CachedNetworkImageProvider(notification.senderProfileImage!)
                  : null,
              child: notification.senderProfileImage == null
                  ? const Icon(Icons.person, color: Colors.white24)
                  : null,
            ),
            const SizedBox(width: AppSpacing.lg),
            
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: AppTextStyles.body.copyWith(color: Colors.white),
                      children: [
                        TextSpan(
                          text: notification.senderUsername,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: notification.type == 'cheers' 
                              ? (notification.activityDate != null 
                                  ? ' cheered your ${DateFormat('MMMM d').format(notification.activityDate!)} 🥂'
                                  : ' cheered your activity 🥂')
                              : notification.type == 'friend_request'
                                  ? ' sent you a friend request 👋'
                                  : ' interacted with you',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(notification.createdAt),
                    style: AppTextStyles.caption.copyWith(
                      color: customColors.textMuted,
                    ),
                  ),
                  if (notification.type == 'friend_request' && !notification.isRead) ...[
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        _buildAction(
                          context, 
                          ref, 
                          'Accept', 
                          Colors.amber, 
                          () => _handleAccept(ref),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _buildAction(
                          context, 
                          ref, 
                          'Ignore', 
                          Colors.white24, 
                          () => _handleIgnore(ref),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Unread indicator
            if (!notification.isRead)
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAction(BuildContext context, WidgetRef ref, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: color == Colors.white24 ? Colors.white70 : color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _handleAccept(WidgetRef ref) {
    ref.read(friendshipRepositoryProvider).acceptFriendRequest(userId, notification.senderId).then((_) {
      ref.read(notificationRepositoryProvider).markAsRead(userId, notification.id);
      ref.invalidate(profileDataProvider);
    });
  }

  void _handleIgnore(WidgetRef ref) {
    ref.read(friendshipRepositoryProvider).rejectFriendRequest(userId, notification.senderId).then((_) {
      ref.read(notificationRepositoryProvider).markAsRead(userId, notification.id);
    });
  }

  Future<void> _handleCheersTap(BuildContext context, WidgetRef ref) async {
    // We need to fetch the logs for the activity being cheered.
    // The activityId is usually userId_yyyy-MM-dd
    final activityId = notification.activityId;
    final activityDate = notification.activityDate;
    
    if (activityDate == null) {
      // Fallback to profile if date is missing
      Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId)));
      return;
    }

    try {
      // Fetch user logs for that date
      final repository = ref.read(drinkLogRepositoryProvider);
      final logs = await repository.fetchLogsForUser(userId); // This is the RECEIVER's logs
      
      // Filter logs by date
      final dateStr = DateFormat('yyyy-MM-dd').format(activityDate);
      final dayLogs = logs.where((l) {
        final lDate = DateFormat('yyyy-MM-dd').format(l.createdAt);
        return lDate == dateStr;
      }).toList();

      if (dayLogs.isEmpty) {
        if (context.mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId)));
        }
        return;
      }

      // Open ActivityDetailViewer
      if (context.mounted) {
        final profileAsync = ref.read(profileDataProvider);
        final userData = profileAsync.value?.userData;

        Navigator.push(
          context,
          PageRouteBuilder(
            opaque: false,
            barrierColor: Colors.black,
            pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
              opacity: animation,
              child: ActivityDetailViewer(
                activityId: activityId,
                initialLogs: dayLogs,
                date: activityDate,
                userId: userId,
                username: userData?.displayName ?? 'You',
                userPhotoUrl: userData?.photoUrl,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId)));
      }
    }
  }
}

class _NotificationsLoadingSkeleton extends StatelessWidget {
  const _NotificationsLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              const AppShimmer(width: 48, height: 48, borderRadius: BorderRadius.all(Radius.circular(24))),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppShimmer(width: double.infinity, height: 16, borderRadius: BorderRadius.all(Radius.circular(4))),
                    const SizedBox(height: 8),
                    AppShimmer(width: 80, height: 12, borderRadius: BorderRadius.circular(4)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
