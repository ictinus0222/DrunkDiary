import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/constants/reaction_config.dart';
import '../../alcohol/models/alcohol_model.dart';
import '../models/drink_model_dto.dart';
import 'log_detail_bottom_sheet.dart';
import '../../../core/widgets/app_shimmer.dart';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/drink_logs_provider.dart';

class DrinkLogCard extends ConsumerWidget {
  final DrinkLogModel log;

  const DrinkLogCard({super.key, required this.log});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPhoto = log.photoUrl != null && log.photoUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          useSafeArea: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => LogDetailBottomSheet(log: log),
        );
      },
      child: hasPhoto ? _buildVerticalLayout(context, ref) : _buildHorizontalLayout(context, ref),
    );
  }

  Widget _buildHorizontalLayout(BuildContext context, WidgetRef ref) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
      height: 120, // Fixed height for horizontal cards to improve performance
      decoration: BoxDecoration(
        color: customColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        border: Border.all(color: customColors.borderDark.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _posterImage(isHorizontal: true, ref: ref),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _titleRow(context),
                    const SizedBox(height: AppSpacing.xs),
                    _metaRow(context),
                    if (log.note != null && log.note!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _caption(context),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    _expressiveFeedback(context),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildVerticalLayout(BuildContext context, WidgetRef ref) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: customColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        border: Border.all(color: customColors.borderDark.withValues(alpha: 0.5), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _posterImage(isHorizontal: false, ref: ref),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _titleRow(context),
                const SizedBox(height: AppSpacing.xs),
                _metaRow(context),
                if (log.note != null && log.note!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _caption(context),
                ],
                const SizedBox(height: AppSpacing.lg),
                _expressiveFeedback(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //* ----------------------------
  // POSTER IMAGE (Bottle or Photo)
  // ----------------------------
  Widget _posterImage({required bool isHorizontal, required WidgetRef ref}) {
    final hasPhoto = log.photoUrl != null && log.photoUrl!.isNotEmpty;

    return Container(
      width: isHorizontal ? 100 : double.infinity,
      height: isHorizontal ? null : 200, // Fixed height for photos in vertical list
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(AppSpacing.radiusDefault),
          bottomLeft: isHorizontal ? const Radius.circular(AppSpacing.radiusDefault) : Radius.zero,
          topRight: isHorizontal ? Radius.zero : const Radius.circular(AppSpacing.radiusDefault),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPhoto
          ? Hero(
              tag: 'alcohol_${log.id}_photo', // Unique tag for the specific log photo
              child: CachedNetworkImage(
                imageUrl: log.photoUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => const AppShimmer(),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            )
          : (log.alcoholId == null 
              ? const Center(child: Icon(Icons.local_bar, color: Colors.white24, size: 30))
              : ref.watch(alcoholCacheProvider(log.alcoholId!)).when(
                  data: (alcohol) {
                    if (alcohol == null) {
                      return const Center(child: Icon(Icons.local_bar, color: Colors.white24, size: 30));
                    }
                    return Hero(
                      tag: 'alcohol_log_${log.id}',
                      child: CachedNetworkImage(
                        imageUrl: alcohol.imageUrl,
                        fit: BoxFit.cover,
                        memCacheWidth: 200, // Optimize image memory
                        placeholder: (context, url) => const AppShimmer(),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(Icons.local_bar, color: Colors.white24, size: 30),
                        ),
                      ),
                    );
                  },
                  loading: () => const AppShimmer(height: double.infinity, width: double.infinity),
                  error: (_, __) => const Center(child: Icon(Icons.local_bar, color: Colors.white24, size: 30)),
                )),
    );
  }

  // Expression row
  Widget _expressiveFeedback(BuildContext context) {

    if (log.logKind == LogKind.review || log.reaction == null) return const SizedBox.shrink();

    final reaction = log.reaction!;
    final label = ReactionConfig.getLabel(reaction);
    final icon = ReactionConfig.getIcon(reaction);
    final color = ReactionConfig.getColor(reaction);

    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // ----------------------------
  // TITLE + RATING
  // ----------------------------
  Widget _titleRow(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            log.alcoholName,
            style: AppTextStyles.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (log.logKind == LogKind.review)
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                index < (log.rating?.round() ?? 0)
                    ? Icons.star
                    : Icons.star_border,
                color: colorScheme.primary,
                size: 14,
              ),
            ),
          ),
      ],
    );
  }

  // ----------------------------
  // DATE + VISIBILITY
  // ----------------------------
  Widget _metaRow(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;

    return Text(
      '${log.alcoholType} • ${_formattedDate()}',
      style: AppTextStyles.caption.copyWith(
        color: customColors.textMuted,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  String _formattedDate() {
    return '${log.createdAt.day} '
        '${_monthName(log.createdAt.month)}, '
        '${log.createdAt.year}';
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  // ----------------------------
  // CAPTION
  // ----------------------------
  Widget _caption(BuildContext context) {
    if (log.note == null || log.note!.isEmpty) {
      return const SizedBox.shrink();
    }
    

    return Text(
      '"${log.note!}"',
      style: AppTextStyles.body.copyWith(
        color: Colors.white.withOpacity(0.9),
        fontStyle: FontStyle.italic,
        height: 1.4,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  // Removed old chips row
}
