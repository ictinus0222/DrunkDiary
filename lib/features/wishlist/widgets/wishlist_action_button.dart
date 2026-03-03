import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

    return StreamBuilder<List<WishlistItemModel>>(
      stream: repo.streamWishlist(userId),
      builder: (context, snapshot) {
        final wishlist = snapshot.data ?? [];
        final isInWishlist =
            wishlist.any((item) => item.alcoholId == alcohol.id);

        return IconButton(
          icon: Icon(
            isInWishlist ? Icons.bookmark : Icons.bookmark_border,
            color: isInWishlist ? Colors.amber : Colors.white,
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
                          style: const TextStyle(color: Colors.white)),
                      backgroundColor: Colors.grey.shade900,
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
                          style: const TextStyle(color: Colors.white)),
                      backgroundColor: Colors.grey.shade900,
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
                        style: const TextStyle(color: Colors.white)),
                    backgroundColor: Colors.redAccent,
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
