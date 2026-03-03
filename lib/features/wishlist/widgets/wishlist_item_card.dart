import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

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
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade900,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => onRemove(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isTried
                  ? Colors.amber.withOpacity(0.5)
                  : Colors.grey.shade800,
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
                            color: Colors.white10,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.amber,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
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
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
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
                                color: Colors.amber.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.amber.withOpacity(0.6)),
                              ),
                              child: const Text(
                                'Tried! 🥃',
                                style: TextStyle(
                                    color: Colors.amber,
                                    fontSize: 11,
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
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.alcoholType,
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 12),
                        ),
                      ),
                      if (item.note != null && item.note!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.sticky_note_2_outlined,
                                size: 13, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.note!,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
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
                    color: Colors.grey.shade600, size: 20),
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: Colors.white10,
      child: const Center(
        child: Icon(Icons.local_bar, size: 32, color: Colors.grey),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Remove from Wishlist',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove "${item.alcoholName}" from your wishlist?',
          style: TextStyle(color: Colors.grey.shade400),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('Cancel', style: TextStyle(color: Colors.grey.shade400)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onRemove();
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
