import 'package:cloud_firestore/cloud_firestore.dart';

import '../../alcohol/models/alcohol_model.dart';
import '../models/wishlist_item_model.dart';

class WishlistRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================
  // 🔖 STREAM USER WISHLIST
  // ============================
  Stream<List<WishlistItemModel>> streamWishlist(String userId) {
    return _firestore
        .collection('wishlists')
        .where('userId', isEqualTo: userId)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(WishlistItemModel.fromFirestore).toList());
  }

  // ============================
  // ➕ ADD TO WISHLIST
  // Prevents duplicates by checking alcoholId first
  // ============================
  Future<void> addToWishlist({
    required String userId,
    required AlcoholModel alcohol,
    String? note,
  }) async {
    // Check for existing entry with same alcoholId
    final existing = await _firestore
        .collection('wishlists')
        .where('userId', isEqualTo: userId)
        .where('alcoholId', isEqualTo: alcohol.id)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('already_in_wishlist');
    }

    final item = WishlistItemModel(
      id: '',
      userId: userId,
      alcoholId: alcohol.id,
      alcoholName: alcohol.name,
      alcoholType: alcohol.type,
      alcoholImageUrl: alcohol.imageUrl,
      note: note?.isNotEmpty == true ? note : null,
      addedAt: DateTime.now(),
    );

    await _firestore.collection('wishlists').add(item.toMap());
  }

  // ============================
  // 🗑️ REMOVE FROM WISHLIST
  // ============================
  Future<void> removeFromWishlist(String wishlistItemId) async {
    await _firestore.collection('wishlists').doc(wishlistItemId).delete();
  }

  // ============================
  // 🔍 CHECK IF ALCOHOL IS IN WISHLIST
  // ============================
  Future<bool> isInWishlist({
    required String userId,
    required String alcoholId,
  }) async {
    final existing = await _firestore
        .collection('wishlists')
        .where('userId', isEqualTo: userId)
        .where('alcoholId', isEqualTo: alcoholId)
        .limit(1)
        .get();
    return existing.docs.isNotEmpty;
  }
}
