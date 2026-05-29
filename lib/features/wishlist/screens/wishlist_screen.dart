import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../../alcohol/models/alcohol_model.dart';
import '../../alcohol/screens/alcohol_detail_screen.dart';
import '../../../core/navigation/page_transitions.dart';
import '../../../core/navigation/tab_change_notification.dart';
import '../models/wishlist_item_model.dart';
import '../widgets/add_to_wishlist_sheet.dart';
import '../widgets/wishlist_item_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../alcohol/repositories/alcohol_repository.dart';
import '../widgets/wishlist_discovery_carousel.dart';
import '../../drink_logs/widgets/create_log_bottom_sheet.dart';
import '../providers/wishlist_providers.dart';
import '../../../core/providers/common_providers.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  static const routeName = '/wishlist';

  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  late final String _userId;

  // Set of alcoholIds that the user has already logged or reviewed
  Set<String> _triedAlcoholIds = {};
  bool _triedLoaded = false;

  // Discovery
  final _alcoholRepo = AlcoholRepository();
  List<AlcoholModel> _discoveryItems = [];
  final bool _isDiscoveryLoading = false;
  List<AlcoholModel> _allAlcohols = [];

  @override
  void initState() {
    super.initState();
    _userId = ref.read(userIdProvider)!;
    _loadTriedIds();
    _loadAllAlcohols();
  }

  Future<void> _loadAllAlcohols() async {
    try {
      final alcohols = await _alcoholRepo.getAllAlcohols();
      if (mounted) {
        setState(() {
          _allAlcohols = alcohols;
        });
      }
    } catch (_) {}
  }

  void _updateDiscovery(List<WishlistItemModel> items) {
    if (_allAlcohols.isEmpty || _isDiscoveryLoading) return;

    // Get categories user is interested in
    final categories = items.map((i) => i.alcoholType).toSet();
    final wishlistIds = items.map((i) => i.alcoholId).toSet();

    // Rank alcohols
    final ranked = List<AlcoholModel>.from(_allAlcohols)
      ..removeWhere((a) => wishlistIds.contains(a.id))
      ..sort((a, b) {
        // 1. Category match
        final aMatch = categories.contains(a.type) ? 1 : 0;
        final bMatch = categories.contains(b.type) ? 1 : 0;
        if (aMatch != bMatch) return bMatch.compareTo(aMatch);

        // 2. Popularity (logCount)
        return b.logCount.compareTo(a.logCount);
      });

    setState(() {
      _discoveryItems = ranked.take(10).toList();
    });
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
      await ref.read(wishlistRepositoryProvider).removeFromWishlist(wishlistItemId);
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
      brand: item.alcoholBrand,
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

  Future<void> _onTryItem(WishlistItemModel item) async {
    final alcohol = await _alcoholRepo.getAlcoholById(item.alcoholId);
    if (alcohol == null) return;

    if (!mounted) return;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateLogBottomSheet(alcohol: alcohol),
    );

    if (result == true) {
      // Success! Move from wishlist to diary
      await _removeItem(item.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Moved from Wishlist to Diary 🍻',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(AppSpacing.xl),
          ),
        );
        _loadTriedIds();
      }
    }
  }

  void _onAddFromDiscovery(AlcoholModel alcohol) async {
    try {
      await ref.read(wishlistRepositoryProvider).addToWishlist(
        userId: _userId,
        alcohol: alcohol,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${alcohol.name} to wishlist')),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('already')
            ? 'Already in your wishlist'
            : 'Could not add to wishlist';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    }
  }

  void _onTapDiscovery(AlcoholModel alcohol) {
    Navigator.push(
      context,
      FadeSlidePageRoute(
        child: AlcoholDetailScreen(
          alcoholId: alcohol.id,
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
    final wishlistAsync = ref.watch(wishlistStreamProvider);

    return Scaffold(
      body: wishlistAsync.when(
        data: (items) {
          if (!_triedLoaded) {
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              slivers: [
                SliverAppBar(
                  floating: true,
                  snap: true,
                  centerTitle: true,
                  title: Text('WISHLIST', style: AppTextStyles.appBarTitle),
                ),
                SliverToBoxAdapter(
                  child: const _WishlistLoadingSkeleton(),
                ),
              ],
            );
          }

          // Trigger discovery update if we have data now
          if (_discoveryItems.isEmpty && _allAlcohols.isNotEmpty) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _updateDiscovery(items));
          }

          if (items.isEmpty) {
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              slivers: [
                SliverAppBar(
                  floating: true,
                  snap: true,
                  centerTitle: true,
                  title: Text('WISHLIST', style: AppTextStyles.appBarTitle),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    children: [
                      AppEmptyState(
                        icon: Icons.bookmark_border,
                        title: 'Nothing saved yet.',
                        subtitle:
                            'Add bottles you want to try and\nbuild your dream shelf.',
                        buttonText: 'Discover Drinks',
                        buttonIcon: Icons.search,
                        onAddTap: () => TabChangeNotification(2)
                            .dispatch(context), // Jump to search
                      ),
                      const SizedBox(height: AppSpacing.hero),
                      WishlistDiscoveryCarousel(
                        recommendations:
                            _discoveryItems.isEmpty && _allAlcohols.isNotEmpty
                                ? _allAlcohols.take(10).toList()
                                : _discoveryItems,
                        onAdd: _onAddFromDiscovery,
                        onTap: _onTapDiscovery,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            );
          }

          return RefreshIndicator(
            color: colorScheme.primary,
            backgroundColor: customColors.cardBackground,
            onRefresh: _loadTriedIds,
            child: Scaffold(
              floatingActionButton: FloatingActionButton.extended(
                onPressed: _openAddSheet,
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.black,
                icon: const Icon(Icons.add),
                label: const Text('Add Bottle',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                heroTag: 'wishlist_fab',
              ),
              body: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                slivers: [
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    centerTitle: true,
                    title: Text('WISHLIST', style: AppTextStyles.appBarTitle),
                  ),
                  SliverPadding(
                    padding: AppSpacing.pagePadding.copyWith(top: 0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = items[index];
                          final isTried =
                              _triedAlcoholIds.contains(item.alcoholId);

                          return Dismissible(
                            key: Key(item.id),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) => _removeItem(item.id),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              margin:
                                  const EdgeInsets.only(bottom: AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: customColors.error.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.delete_outline,
                                  color: Colors.white, size: 28),
                            ),
                            child: WishlistItemCard(
                              item: item,
                              isTried: isTried,
                              onRemove: () => _removeItem(item.id),
                              onTry: () => _onTryItem(item),
                              onTap: () => _navigateToDetail(item),
                            ),
                          );
                        },
                        childCount: items.length,
                      ),
                    ),
                  ),
                  if (items.length <= 2) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xxl),
                        child: WishlistDiscoveryCarousel(
                          recommendations: _discoveryItems,
                          onAdd: _onAddFromDiscovery,
                          onTap: _onTapDiscovery,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Center(
                        child: Text(
                          'Keep building your wishlist.',
                          style: textTheme.bodySmall?.copyWith(
                            color: customColors.textMuted.withValues(alpha: 0.5),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ] else
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          );
        },
        loading: () => CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              centerTitle: true,
              title: Text('WISHLIST', style: AppTextStyles.appBarTitle),
            ),
            SliverToBoxAdapter(
              child: const _WishlistLoadingSkeleton(),
            ),
          ],
        ),
        error: (err, stack) => CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              centerTitle: true,
              title: Text('WISHLIST', style: AppTextStyles.appBarTitle),
            ),
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'Something went wrong.',
                  style: textTheme.bodyMedium
                      ?.copyWith(color: customColors.textMuted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ----------------------------- SKELETONS ----------------------------- */

class _WishlistLoadingSkeleton extends StatelessWidget {
  const _WishlistLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        5,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
          child: AppShimmer(
            height: 90,
            borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
          ),
        ),
      ),
    );
  }
}
