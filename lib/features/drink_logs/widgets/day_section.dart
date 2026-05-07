import 'package:flutter/material.dart';
import '../../../app/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/drink_model_dto.dart';
import 'horizontal_scroll_log_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/drink_logs_provider.dart';
import '../../activity/providers/activity_providers.dart';
import 'cheers_button.dart';
import '../../profile/screens/profile_screen.dart';
import '../../activity/screens/activity_detail_viewer.dart';
import '../../../core/navigation/tab_change_notification.dart';
import '../../../core/providers/common_providers.dart';
import '../../profile/providers/profile_providers.dart';

/// Groups one day's logs into a timeline-style activity cluster.
///
/// Structure:
/// ┌──────┬────────────────────────────┐
/// │ 03   │  (Avatar) (Username)       │
/// │ MAY  │  [ log ] [ log ] [ log ] → 
class DayActivityCard extends ConsumerWidget {
  final DateTime date;
  final List<DrinkLogModel> logs;
  final bool showUser;

  const DayActivityCard({
    super.key,
    required this.date,
    required this.logs,
    this.showUser = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (logs.isEmpty) return const SizedBox.shrink();
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final firstLog = logs.first;
    final localDate = date.toLocal();

    final dateString = "${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}";
    final activityId = "${firstLog.userId}_$dateString";

    final activityAsync = ref.watch(dayActivityProvider(activityId));
    final profileAsync = ref.watch(profileDataProvider);
    final viewer = profileAsync.value?.userData;
    final isFriend = viewer != null && viewer.friends.contains(firstLog.userId);
    
    final isPrivateSession = logs.any((l) => l.isPrivate);
    
    // A session is ONLY effectively private if the viewer is not the owner AND not a friend
    final isEffectivelyPrivate = isPrivateSession && 
                                firstLog.userId != viewer?.id && 
                                !isFriend;

    return Column(
      children: [
        const SizedBox(height: AppSpacing.xxl),
        
        // ── 👤 HEADER (DATE + USER) ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 📅 Left: Date
              _DateColumn(localDate: localDate),
              const SizedBox(width: 12),
              // 👉 Right: User Info
              if (showUser)
                Expanded(
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          final currentUserId = viewer?.id;
                          if (firstLog.userId == currentUserId) {
                            const TabChangeNotification(4).dispatch(context);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfileScreen(userId: firstLog.userId),
                              ),
                            );
                          }
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.amber,
                              backgroundImage: firstLog.userPhotoUrl != null
                                  ? CachedNetworkImageProvider(firstLog.userPhotoUrl!)
                                  : null,
                              child: firstLog.userPhotoUrl == null
                                  ? const Icon(Icons.person, size: 24, color: Colors.black)
                                  : null,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              "@${firstLog.username}",
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.more_horiz, color: Colors.white54),
                        onPressed: () => _showComingSoon(context),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── 🖼 FULL-WIDTH HORIZONTAL LOG SCROLL ──────────────────────────────
        _HorizontalLogScroll(
          logs: logs,
          onLogTap: (index) => _openViewer(context, ref, index, activityId, isEffectivelyPrivate),
        ),

        const SizedBox(height: 4),

        // ── 📊 FOOTER (COUNT + SHARE) ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              const SizedBox(width: 56 + 12),
              if (!isEffectivelyPrivate)
                activityAsync.when(
                  data: (activity) => CheersButton(
                    activityId: activityId,
                    activityOwnerId: firstLog.userId,
                    activityDate: date,
                    activityData: activity,
                  ),
                  loading: () => CheersButton(
                    activityId: '',
                    activityOwnerId: '',
                    activityDate: DateTime(2000),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              if (isEffectivelyPrivate)
                Row(
                  children: [
                    Icon(Icons.lock_outline, size: 14, color: customColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'PRIVATE',
                      style: AppTextStyles.caption.copyWith(
                        color: customColors.textMuted,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              const Spacer(),
              Text(
                '${logs.length} ${logs.length == 1 ? 'LOG' : 'LOGS'}',
                style: AppTextStyles.caption.copyWith(
                  color: customColors.textMuted,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              IconButton(
                icon: const Icon(Icons.ios_share, size: 18, color: Colors.white54),
                onPressed: () => _showComingSoon(context),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xxl),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Divider(
            height: 8,
            thickness: 1.0,
            color: customColors.borderDark,
          ),
        ),
      ],
    );
  }

  void _openViewer(BuildContext context, WidgetRef ref, int initialIndex, String activityId, bool isEffectivelyPrivate) {
    final firstLog = logs.first;
    
    if (isEffectivelyPrivate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This session is private')),
      );
      return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: ActivityDetailViewer(
            activityId: activityId,
            initialLogs: logs,
            date: date,
            userId: firstLog.userId,
            username: firstLog.username,
            userPhotoUrl: firstLog.userPhotoUrl,
            initialPageIndex: initialIndex,
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming Soon'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getMonthAbbr(int month) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return months[month - 1];
  }
}

class _DateColumn extends StatelessWidget {
  final DateTime localDate;

  const _DateColumn({required this.localDate});

  String _getMonthAbbr(int month) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: Column(
        children: [
          Text(
            localDate.day.toString().padLeft(2, '0'),
            style: GoogleFonts.dmSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          Text(
            _getMonthAbbr(localDate.month),
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white60,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Horizontal scroll row ─────────────────────────────────────────────────────

class _HorizontalLogScroll extends StatelessWidget {
  final List<DrinkLogModel> logs;
  final Function(int) onLogTap;

  const _HorizontalLogScroll({required this.logs, required this.onLogTap});

  @override
  Widget build(BuildContext context) {
    // 84px = 16px (page padding) + 56px (date column) + 12px (gap)
    const double leftOffset = AppSpacing.lg + 56 + 12;

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        // Padding allows the first card to align with the username, 
        // while the list can scroll all the way to the left screen edge.
        padding: const EdgeInsets.only(
          left: leftOffset,
          right: AppSpacing.lg,
        ),
        itemCount: logs.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) => LogMiniCard(
          log: logs[index],
          onTap: () => onLogTap(index),
        ),
      ),
    );
  }
}
