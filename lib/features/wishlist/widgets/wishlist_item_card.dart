import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/wishlist_item_model.dart';

class WishlistItemCard extends StatelessWidget {
  final WishlistItemModel item;
  final bool isTried;
  final VoidCallback onRemove;
  final VoidCallback onTry;
  final VoidCallback onTap;

  const WishlistItemCard({
    super.key,
    required this.item,
    required this.isTried,
    required this.onRemove,
    required this.onTry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: customColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isTried
              ? colorScheme.primary.withValues(alpha: 0.5)
              : customColors.borderDark,
          width: isTried ? 1.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // 1. Premium Bottle Thumbnail Container
                  _buildPremiumImage(context),
                  const SizedBox(width: 16),
                  
                  // 2. Center Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.alcoholName,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.alcoholBrand.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.alcoholBrand,
                            style: textTheme.bodySmall?.copyWith(
                              color: customColors.textMuted,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        // Type Pill
                        _buildTypePill(context),
                        
                        // Recommendation
                        if (item.note != null && item.note!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _buildRecommendation(context),
                        ],
                      ],
                    ),
                  ),
                  
                  // 3. Actions Right
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Delete subtle icon
                      IconButton(
                        onPressed: () => _confirmDelete(context),
                        icon: Icon(
                          Icons.delete_outline,
                          color: customColors.textMuted.withOpacity(0.3),
                          size: 18,
                        ),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(height: 12),
                      // Log Gold Button
                      _buildLogButton(context),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumImage(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: 84, // Size 72-84
      height: 84,
      decoration: BoxDecoration(
        color: customColors.deepCardBackground, // Soft dark surface
        borderRadius: BorderRadius.circular(14), // Radius 14
        border: Border.all(color: customColors.borderDark, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8), // Center aligned with proper padding
      child: item.alcoholImageUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: item.alcoholImageUrl,
              fit: BoxFit.contain, // Maintain aspect ratio, no stretched image
              placeholder: (_, __) => Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: colorScheme.primary.withOpacity(0.3),
                    strokeWidth: 1.5,
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => Icon(
                Icons.local_bar_outlined,
                color: customColors.textMuted.withOpacity(0.5),
                size: 32,
              ),
            )
          : Icon(
              Icons.local_bar_outlined,
              color: customColors.textMuted.withOpacity(0.5),
              size: 32,
            ),
    );
  }

  Widget _buildTypePill(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: customColors.borderDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        item.alcoholType,
        style: textTheme.labelSmall?.copyWith(
          color: customColors.textMuted,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRecommendation(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final textTheme = Theme.of(context).textTheme;
    
    final isRecommendation = item.note!.toLowerCase().contains('recommended by');
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isRecommendation ? Icons.verified_user_outlined : Icons.sticky_note_2_outlined,
          size: 10,
          color: customColors.textMuted.withOpacity(0.5),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            item.note!,
            style: textTheme.bodySmall?.copyWith(
              color: customColors.textMuted.withOpacity(0.6),
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLogButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return GestureDetector(
      onTap: onTry,
      child: Container(
        height: 38, // Height 36-40
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: colorScheme.primary, // Gold primary
          borderRadius: BorderRadius.circular(16), // Radius 16
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '+ Log', // Renamed to "+ Log"
          style: textTheme.labelLarge?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final textTheme = Theme.of(context).textTheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: customColors.deepCardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remove Item', style: textTheme.titleLarge),
        content: Text(
          'Remove "${item.alcoholName}" from your wishlist?',
          style: textTheme.bodyMedium?.copyWith(color: customColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: textTheme.labelLarge?.copyWith(color: customColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onRemove();
            },
            child: Text('Remove',
                style: textTheme.labelLarge?.copyWith(color: customColors.error)),
          ),
        ],
      ),
    );
  }
}
