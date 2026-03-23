import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../alcohol/models/alcohol_model.dart';
import '../../alcohol/screens/alcohol_detail_screen.dart';
import '../../../core/navigation/page_transitions.dart';
import '../models/wishlist_item_model.dart';
import '../repositories/wishlist_repository.dart';
import '../widgets/add_to_wishlist_sheet.dart';
import '../widgets/wishlist_item_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/custom_app_bar.dart';

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
          SnackBar(
            content: Text('Could not remove item.',
                style: TextStyle(color: Theme.of(context).colorScheme.onError)),
            backgroundColor: Theme.of(context).colorScheme.error,
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
      FadeSlidePageRoute(
        child: AlcoholDetailScreen(
          alcoholId: item.alcoholId,
          initialAlcohol: alcohol,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Wishlist'),
      body: StreamBuilder<List<WishlistItemModel>>(
        stream: _wishlistRepo.streamWishlist(_userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              !_triedLoaded) {
            return const _WishlistLoadingSkeleton();
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Something went wrong.',
                style: textTheme.bodyMedium?.copyWith(color: customColors.textMuted),
              ),
            );
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return AppEmptyState(
              icon: Icons.bookmark_border,
              title: 'Your wishlist is empty',
              subtitle:
                  'Save drinks you\'ve heard about\nand want to try later.',
              buttonText: 'Add Your First Drink',
              buttonIcon: Icons.bookmark_add,
              onAddTap: _openAddSheet,
            );
          }

          return RefreshIndicator(
            color: colorScheme.primary,
            backgroundColor: customColors.cardBackground,
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
/* ----------------------------- SKELETONS ----------------------------- */

class _WishlistLoadingSkeleton extends StatelessWidget {
  const _WishlistLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: AppShimmer(
          height: 90,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
