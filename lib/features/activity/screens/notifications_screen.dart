import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../app/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../providers/notifications_provider.dart';
import '../models/notification_model.dart';
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
                              ? ' cheered your activity 🥂' 
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
