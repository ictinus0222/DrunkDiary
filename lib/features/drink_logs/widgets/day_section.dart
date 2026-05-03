import 'package:flutter/material.dart';
import '../../../app/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/drink_model_dto.dart';
import 'horizontal_scroll_log_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

/// Groups one day's logs into a timeline-style activity cluster.
///
/// Structure:
/// ┌──────┬────────────────────────────┐
/// │ 03   │  (Avatar) (Username)       │
/// │ MAY  │  [ log ] [ log ] [ log ] → │
/// │      │  3 LOGS                    │
/// └──────┴────────────────────────────┘
class DayActivityCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (logs.isEmpty) return const SizedBox.shrink();
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final firstLog = logs.first;
    final localDate = date.toLocal();

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
        // Moved outside the constrained column to allow edge-to-edge scrolling.
        _HorizontalLogScroll(logs: logs),

        const SizedBox(height: 4),

        // ── 📊 FOOTER (COUNT + SHARE) ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              // Spacer to align with the right column content (56px date + 12px gap)
              const SizedBox(width: 56 + 12),
              Text(
                '${logs.length} ${logs.length == 1 ? 'LOG' : 'LOGS'}',
                style: AppTextStyles.caption.copyWith(
                  color: customColors.textMuted,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
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
        
        // ── ➖ SEPARATING BAR ──────────────────────────────────────────────
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

  const _HorizontalLogScroll({required this.logs});

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
        itemBuilder: (context, index) => LogMiniCard(log: logs[index]),
      ),
    );
  }
}
