import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../../alcohol/models/alcohol_model.dart';
import '../../../core/providers/common_providers.dart';
import '../providers/wishlist_providers.dart';

class WishlistActionButton extends ConsumerWidget {
  final AlcoholModel alcohol;

  const WishlistActionButton({
    super.key,
    required this.alcohol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(userIdProvider);
    if (userId == null) return const SizedBox.shrink();

    final wishlistAsync = ref.watch(wishlistStreamProvider);
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return wishlistAsync.when(
      data: (wishlist) {
        final isInWishlist = wishlist.any((item) => item.alcoholId == alcohol.id);

        return IconButton(
          icon: Icon(
            isInWishlist ? Icons.bookmark : Icons.bookmark_border,
            color: isInWishlist ? colorScheme.primary : colorScheme.onSurface,
          ),
          onPressed: () async {
            final repo = ref.read(wishlistRepositoryProvider);
            try {
              if (isInWishlist) {
                final item = wishlist.firstWhere((item) => item.alcoholId == alcohol.id);
                await repo.removeFromWishlist(item.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${alcohol.name} removed from wishlist',
                          style: TextStyle(color: colorScheme.onSurface)),
                      backgroundColor: customColors.deepCardBackground,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } else {
                await repo.addToWishlist(userId: userId, alcohol: alcohol);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${alcohol.name} added to wishlist',
                          style: TextStyle(color: colorScheme.onSurface)),
                      backgroundColor: customColors.deepCardBackground,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating wishlist',
                        style: TextStyle(color: colorScheme.onError)),
                    backgroundColor: customColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
        );
      },
      loading: () => IconButton(
        icon: Icon(Icons.bookmark_border, color: colorScheme.onSurface.withValues(alpha: 0.3)),
        onPressed: null,
      ),
      error: (_, __) => IconButton(
        icon: Icon(Icons.bookmark_border, color: colorScheme.onSurface.withValues(alpha: 0.3)),
        onPressed: null,
      ),
    );
  }
}
