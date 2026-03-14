import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../alcohol/screens/alcohol_detail_screen.dart';
import '../models/discover_item_model.dart';

class DiscoverAlcoholCard extends StatelessWidget {
  final DiscoverItemModel item;

  const DiscoverAlcoholCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AlcoholDetailScreen(alcohol: item.alcohol),
          ),
        );
      },
      child: Container(
        height: 120,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: customColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch, // fill height
          children: [
            // Image Wrapper
            Container(
              width: 110,
              decoration: BoxDecoration(
                color: colorScheme.onSurface, // White usually for images
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: item.alcohol.imageUrl.isNotEmpty
                      ? Image.network(
                          item.alcohol.imageUrl,
                          fit: BoxFit.contain,
                        )
                      : Icon(Icons.local_bar,
                          color: customColors.textMuted, size: 40),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand and Type Chip
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.alcohol.brand,
                            style: textTheme.bodySmall?.copyWith(
                              color: customColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: colorScheme.primary.withOpacity(0.5)),
                          ),
                          child: Text(
                            item.alcohol.type,
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Name
                    Text(
                      item.alcohol.name,
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Rating & Indicator
                    Row(
                      children: [
                        Icon(Icons.star, color: colorScheme.primary, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          item.reviewCount > 0
                              ? item.globalRating.toStringAsFixed(1)
                              : 'New',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (item.reviewCount > 0)
                          Text(
                            ' (${item.reviewCount})',
                            style: textTheme.bodySmall?.copyWith(
                              color: customColors.textMuted,
                            ),
                          ),
                        const Spacer(),
                        if (item.hasUserReviewed || item.hasUserLogged)
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: customColors.success,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.hasUserReviewed ? 'Reviewed' : 'Logged',
                                style: textTheme.labelSmall?.copyWith(
                                  color: customColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            ],
                          ),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
