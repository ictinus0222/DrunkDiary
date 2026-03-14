import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../models/drink_model_dto.dart';
import 'log_detail_bottom_sheet.dart';

class DrinkLogCard extends StatelessWidget {
  final DrinkLogModel log;

  const DrinkLogCard({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;

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
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: log.logKind == LogKind.review
              ? customColors.cardBackground
              : customColors.deepCardBackground,
          border: Border.all(
            color: log.logKind == LogKind.review
                ? customColors.borderLight
                : customColors.borderDark,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerImage(),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _titleRow(context),
                  const SizedBox(height: 6),
                  _metaRow(context),
                  const SizedBox(height: 14),
                  _caption(context),
                  const SizedBox(height: 14),
                  _chipsRow(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------
  // HEADER IMAGE
  // ----------------------------
  Widget _headerImage() {
    if (log.photoUrl == null || log.photoUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          log.photoUrl!,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // ----------------------------
  // TITLE + RATING
  // ----------------------------
  Widget _titleRow(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final customColors = Theme.of(context).extension<AppCustomColors>()!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            log.alcoholName,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
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
                size: 16,
              ),
            ),
          )
        else
          Icon(
            log.isLiked == true ? Icons.thumb_up : Icons.thumb_down,
            color: log.isLiked == true ? customColors.success : customColors.error,
            size: 20,
          ),
      ],
    );
  }

  // ----------------------------
  // DATE + VISIBILITY
  // ----------------------------
  Widget _metaRow(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Text(
      _formattedDate(),
      style: textTheme.bodySmall?.copyWith(
        color: customColors.textMuted,
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
    
    final textTheme = Theme.of(context).textTheme;
    final customColors = Theme.of(context).extension<AppCustomColors>()!;

    return Text(
      log.note!,
      style: textTheme.bodyMedium?.copyWith(
        color: customColors.textMuted,
      ),
    );
  }

  // ----------------------------
  // INFO CHIPS (model-safe)
  // ----------------------------
  Widget _chipsRow(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip(context, log.alcoholType),
        _chip(context, log.logKind == LogKind.review ? 'Review' : 'Log'),
      ],
    );
  }

  Widget _chip(BuildContext context, String text) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: customColors.borderDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
