import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../models/wishlist_item_model.dart';

class WishlistItemCard extends StatelessWidget {
  final WishlistItemModel item;
  final bool isTried;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const WishlistItemCard({
    super.key,
    required this.item,
    required this.isTried,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: customColors.error.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: colorScheme.onError, size: 28),
      ),
      onDismissed: (_) => onRemove(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: customColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isTried
                  ? colorScheme.primary.withOpacity(0.5)
                  : customColors.borderDark,
              width: isTried ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Alcohol image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: SizedBox(
                  width: 80,
                  height: 90,
                  child: item.alcoholImageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.alcoholImageUrl,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => Container(
                            color: colorScheme.onSurface.withOpacity(0.1),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: colorScheme.primary,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => _imagePlaceholder(context),
                        )
                      : _imagePlaceholder(context),
                ),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.alcoholName,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isTried)
                            Container(
                              margin: const EdgeInsets.only(left: 8, right: 12),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: colorScheme.primary.withOpacity(0.6)),
                              ),
                              child: Text(
                                'Tried! 🥃',
                                style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Type chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: customColors.borderDark,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.alcoholType,
                          style: textTheme.bodySmall?.copyWith(
                              color: customColors.textMuted),
                        ),
                      ),
                      if (item.note != null && item.note!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.sticky_note_2_outlined,
                                size: 13, color: customColors.textMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.note!,
                                style: textTheme.bodySmall?.copyWith(
                                  color: customColors.textMuted,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Delete button
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: customColors.textMuted, size: 20),
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.onSurface.withOpacity(0.1),
      child: Center(
        child: Icon(Icons.local_bar, size: 32, color: customColors.textMuted),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final textTheme = Theme.of(context).textTheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: customColors.cardBackground,
        title: Text('Remove from Wishlist',
            style: textTheme.titleLarge),
        content: Text(
          'Remove "${item.alcoholName}" from your wishlist?',
          style: textTheme.bodyMedium?.copyWith(color: customColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('Cancel', style: textTheme.labelLarge?.copyWith(color: customColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onRemove();
            },
            child: Text('Remove', style: textTheme.labelLarge?.copyWith(color: customColors.error)),
          ),
        ],
      ),
    );
  }
}
