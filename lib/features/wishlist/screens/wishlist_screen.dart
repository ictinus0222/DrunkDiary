import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../alcohol/models/alcohol_model.dart';
import '../../alcohol/screens/alcohol_detail_screen.dart';
import '../models/wishlist_item_model.dart';
import '../repositories/wishlist_repository.dart';
import '../widgets/add_to_wishlist_sheet.dart';
import '../widgets/wishlist_item_card.dart';

class WishlistScreen extends StatefulWidget {
  static const routeName = '/wishlist';

  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final _wishlistRepo = WishlistRepository();
  late final String _userId;

  // Set of alcoholIds that the user has already logged or reviewed
  Set<String> _triedAlcoholIds = {};
  bool _triedLoaded = false;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser!.uid;
    _loadTriedIds();
  }

  /// Loads all alcoholIds from the user's drink_logs collection
  /// so we can show the "Tried!" badge on wishlist items.
  Future<void> _loadTriedIds() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('drink_logs')
        .where('userId', isEqualTo: _userId)
        .get();

    final ids =
        snapshot.docs.map((d) => d.data()['alcoholId'] as String).toSet();

    if (mounted) {
      setState(() {
        _triedAlcoholIds = ids;
        _triedLoaded = true;
      });
    }
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const AddToWishlistSheet(),
      ),
    ).then((_) => _loadTriedIds()); // Refresh tried IDs after sheet closes
  }

  Future<void> _removeItem(String wishlistItemId) async {
    try {
      await _wishlistRepo.removeFromWishlist(wishlistItemId);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not remove item.',
                style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToDetail(WishlistItemModel item) {
    // Build a minimal AlcoholModel from denormalized data
    final alcohol = AlcoholModel(
      id: item.alcoholId,
      name: item.alcoholName,
      type: item.alcoholType,
      brand: '',
      abv: 0,
      origin: '',
      description: '',
      imageUrl: item.alcoholImageUrl,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AlcoholDetailScreen(alcohol: alcohol),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Wishlist',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.bookmark_add),
        label: const Text(
          'Add Drink',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<WishlistItemModel>>(
        stream: _wishlistRepo.streamWishlist(_userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              !_triedLoaded) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Something went wrong.',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            );
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return _EmptyState(onAddTap: _openAddSheet);
          }

          return RefreshIndicator(
            color: Colors.amber,
            backgroundColor: const Color(0xFF1A1A1A),
            onRefresh: _loadTriedIds,
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 100),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isTried = _triedAlcoholIds.contains(item.alcoholId);
                return WishlistItemCard(
                  item: item,
                  isTried: isTried,
                  onRemove: () => _removeItem(item.id),
                  onTap: () => _navigateToDetail(item),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddTap;
  const _EmptyState({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber.withOpacity(0.1),
                border:
                    Border.all(color: Colors.amber.withOpacity(0.3), width: 2),
              ),
              child: const Icon(
                Icons.bookmark_border,
                color: Colors.amber,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your wishlist is empty',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Save drinks you\'ve heard about\nand want to try later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAddTap,
              icon: const Icon(Icons.bookmark_add, color: Colors.black),
              label: const Text(
                'Add Your First Drink',
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
