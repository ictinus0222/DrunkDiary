import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/constants/reaction_config.dart';
import '../models/drink_model_dto.dart';
import 'log_detail_bottom_sheet.dart';
import '../../../core/widgets/app_shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/drink_logs_provider.dart';

import 'participant_avatars.dart';

/// Image-first compact card for the [DayActivityCard] horizontal scroll row.
///
/// Layout (170×220):
/// ┌──────────────────────────┐
/// │                          │
/// │      (Log Image)         │
/// │                          │
/// │  ░░░ gradient overlay ░░ │
/// │  Bombay Sapphire  ⭐ 3.5 │
/// │  3:24 PM                 │
/// └──────────────────────────┘
class LogMiniCard extends ConsumerWidget {
  final DrinkLogModel log;
  final VoidCallback? onTap;

  const LogMiniCard({super.key, required this.log, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap ?? () {
        showModalBottomSheet(
          context: context,
          useSafeArea: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => LogDetailBottomSheet(log: log),
        );
      },
      child: SizedBox(
        width: 170,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Clipped image + overlay + name/rating ─────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
              child: SizedBox(
                width: 170,
                height: 190,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _ImageLayer(log: log),
                    _GradientOverlay(),
                    Positioned(
                      left: AppSpacing.md,
                      right: AppSpacing.md,
                      bottom: AppSpacing.md,
                      child: _BottomContent(log: log),
                    ),
                    Positioned(
                      left: AppSpacing.sm,
                      top: AppSpacing.sm,
                      child: ParticipantAvatars(log: log, radius: 10),
                    ),
                  ],
                ),
              ),
            ),

            // ── Time — below image, scrolls with card ─────────────────────
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.xs,
                left: AppSpacing.xs,
              ),
              child: Text(
                _formattedTime(log.createdAt),
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formattedTime(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  }
}

// ── Image layer ───────────────────────────────────────────────────────────────

class _ImageLayer extends ConsumerWidget {
  final DrinkLogModel log;
  const _ImageLayer({required this.log});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // Prefer the user's captured photo
    if (log.photoUrl != null && log.photoUrl!.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: AppColors.getAlcoholGradient(log.alcoholType),
        ),
        child: CachedNetworkImage(
          imageUrl: log.photoUrl!,
          fit: BoxFit.cover,
          memCacheWidth: 600,
          placeholder: (_, __) => const AppShimmer(),
          errorWidget: (_, __, ___) => _FallbackBackground(log: log),
        ),
      );
    }

    if (log.alcoholId == null) {
      return _FallbackBackground(log: log);
    }

    return ref.watch(alcoholCacheProvider(log.alcoholId!)).when(
      data: (alcohol) {
        if (alcohol == null) return _FallbackBackground(log: log);
        return Container(
          decoration: BoxDecoration(
            gradient: AppColors.getAlcoholGradient(log.alcoholType),
          ),
          child: CachedNetworkImage(
            imageUrl: alcohol.imageUrl,
            fit: BoxFit.cover,
            memCacheWidth: 250, // Mini cards are small
            placeholder: (_, __) => const AppShimmer(),
            errorWidget: (_, __, ___) => _FallbackBackground(log: log),
          ),
        );
      },
      loading: () => const AppShimmer(),
      error: (_, __) => _FallbackBackground(log: log),
    );
  }
}

class _FallbackBackground extends StatelessWidget {
  final DrinkLogModel log;
  const _FallbackBackground({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.getAlcoholGradient(log.alcoholType),
      ),
      child: const Center(
        child: Icon(Icons.local_bar, color: Colors.white12, size: 36),
      ),
    );
  }
}

// ── Gradient overlay ──────────────────────────────────────────────────────────

class _GradientOverlay extends StatelessWidget {
  const _GradientOverlay();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.center,
          colors: [
            Colors.black.withValues(alpha: 0.82),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

// ── Bottom text content (on image) ───────────────────────────────────────────
// Shows only name + rating — overlaid on the image via gradient.
// Time is rendered OUTSIDE this stack, below the ClipRRect.

class _BottomContent extends StatelessWidget {
  final DrinkLogModel log;
  const _BottomContent({required this.log});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            log.alcoholName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        _RatingBadge(log: log),
      ],
    );
  }
}

// ── Single rating badge ───────────────────────────────────────────────────────

class _RatingBadge extends StatelessWidget {
  final DrinkLogModel log;
  const _RatingBadge({required this.log});

  @override
  Widget build(BuildContext context) {
    if (log.logKind == LogKind.review && log.rating != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
          const SizedBox(width: 2),
          Text(
            log.rating!.toStringAsFixed(1),
            style: AppTextStyles.caption.copyWith(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      );
    }

    if (log.reaction != null) {
      return Icon(
        ReactionConfig.getIcon(log.reaction!),
        color: ReactionConfig.getColor(log.reaction!),
        size: 13,
      );
    }

    return const SizedBox.shrink();
  }
}
