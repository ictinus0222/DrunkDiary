import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../drink_logs/models/drink_model_dto.dart';

class PublicLogTile extends StatelessWidget {
  final DrinkLogModel log;

  const PublicLogTile({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Username + Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Theme.of(context).extension<AppCustomColors>()!.borderLight,
                      backgroundImage: log.userPhotoUrl != null
                          ? NetworkImage(log.userPhotoUrl!)
                          : null,
                      child: log.userPhotoUrl == null
                          ? Text(
                              log.username.isNotEmpty
                                  ? log.username[0].toUpperCase()
                                  : '?',
                              style: textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      log.username,
                      style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                if (log.logKind == LogKind.review)
                  Text('⭐ ${(log.rating ?? 0.0).toStringAsFixed(1)}', style: textTheme.bodyMedium)
                else
                  Text(log.isLiked == true ? '👍' : '👎', style: textTheme.bodyMedium),
              ],
            ),

            if (log.note != null && log.note!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                log.note!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
