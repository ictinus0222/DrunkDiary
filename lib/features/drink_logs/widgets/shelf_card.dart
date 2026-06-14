import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../alcohol/models/alcohol_model.dart';
import '../../alcohol/screens/alcohol_detail_screen.dart';
import '../../../core/navigation/page_transitions.dart';
import '../../../core/widgets/app_shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ShelfCard extends StatelessWidget {
  final AlcoholModel alcohol;
  final int logCount;
  final double avgRating;

  const ShelfCard({
    super.key,
    required this.alcohol,
    required this.logCount,
    required this.avgRating,
  });

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final colorScheme = Theme.of(context).colorScheme;

    // Using star for items that have a rating > 0, otherwise heart
    final bool hasRating = avgRating > 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          FadeSlidePageRoute(
            child: AlcoholDetailScreen(
              alcoholId: alcohol.id,
              initialAlcohol: alcohol,
              heroTag: 'shelf_alcohol_${alcohol.id}',
            ),
          ),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // The Box/Image
          Container(
            decoration: BoxDecoration(boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.6),
                blurRadius: 15,
                offset: const Offset(0, 10),
              )
            ]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: AspectRatio(
                aspectRatio: 0.75,
                child: Hero(
                  tag: 'shelf_alcohol_${alcohol.id}',
                  child: CachedNetworkImage(
                    imageUrl: alcohol.imageUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 300, // Cards are small on the shelf
                    placeholder: (context, url) => const AppShimmer(),
                    errorWidget: (context, url, error) => Container(
                      color: customColors.cardBackground,
                      child: Center(
                        child: Icon(Icons.local_bar, size: 40, color: customColors.textMuted),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // The floating badge
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: customColors.cardBackground,
              ),
              padding: const EdgeInsets.all(4),
              child: Icon(hasRating ? Icons.star : Icons.favorite,
                  color: colorScheme.primary, size: 12),
            ),
          )
        ],
      ),
    );
  }
}
