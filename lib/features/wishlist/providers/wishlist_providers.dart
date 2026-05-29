import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/wishlist_repository.dart';
import '../models/wishlist_item_model.dart';
import '../../../core/providers/common_providers.dart';

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return WishlistRepository();
});

final wishlistStreamProvider = StreamProvider<List<WishlistItemModel>>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) {
    return Stream.value([]);
  }
  final repository = ref.watch(wishlistRepositoryProvider);
  return repository.streamWishlist(userId);
});
