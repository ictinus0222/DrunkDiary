import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../app/app_theme.dart';
import '../../alcohol/models/alcohol_model.dart';
import '../repositories/wishlist_repository.dart';
import '../models/wishlist_item_model.dart';

class WishlistActionButton extends StatelessWidget {
  final AlcoholModel alcohol;

  const WishlistActionButton({
    super.key,
    required this.alcohol,
  });

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    final repo = WishlistRepository();
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<List<WishlistItemModel>>(
      stream: repo.streamWishlist(userId),
      builder: (context, snapshot) {
        final wishlist = snapshot.data ?? [];
        final isInWishlist =
            wishlist.any((item) => item.alcoholId == alcohol.id);

        return IconButton(
          icon: Icon(
            isInWishlist ? Icons.bookmark : Icons.bookmark_border,
            color: isInWishlist ? colorScheme.primary : colorScheme.onSurface,
          ),
          onPressed: () async {
            try {
              if (isInWishlist) {
                final item =
                    wishlist.firstWhere((item) => item.alcoholId == alcohol.id);
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
    );
  }
}
