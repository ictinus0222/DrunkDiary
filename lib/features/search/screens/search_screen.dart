import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/analytics/analytics_service.dart';

import '../../../app/app_theme.dart';
import '../../alcohol/repositories/alcohol_repository.dart';
import '../../drink_logs/models/drink_model_dto.dart';
import '../../wishlist/screens/wishlist_screen.dart';
import '../models/discover_item_model.dart';
import '../widgets/discover_alcohol_card.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _alcoholRepo = AlcoholRepository();

  bool _isLoading = true;
  String _error = '';

  List<DiscoverItemModel> _allAlcohols = [];
  List<DiscoverItemModel> _filteredAlcohols = [];
  List<String> _availableTypes = [];

  // Filter & Sort State
  String _searchQuery = '';
  DiscoverSortOption _selectedSort = DiscoverSortOption.random;
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;

      // 1. Fetch Alcohols
      final alcohols = await _alcoholRepo.getAllAlcohols();

      // 2. Fetch Public Logs for global ratings
      final logsSnapshot = await FirebaseFirestore.instance.collection('drink_logs')
          .where('isPrivate', isEqualTo: false)
          .get();
      
      // Also fetch current user's logs (even if private) to show their history
      final myLogsSnapshot = await FirebaseFirestore.instance.collection('drink_logs')
          .where('userId', isEqualTo: user.uid)
          .get();

      final rawLogs = [
        ...logsSnapshot.docs.map(DrinkLogModel.fromFirestore),
        ...myLogsSnapshot.docs.map(DrinkLogModel.fromFirestore),
      ];

      // De-duplicate if needed (though userId == currentUid and isPrivate == false overlap)
      final logsMap = {for (var log in rawLogs) log.id: log};
      final logs = logsMap.values.toList();

      // 3. Process Data
      final Set<String> typesList = {};
      final List<DiscoverItemModel> items = [];

      for (var alcohol in alcohols) {
        typesList.add(alcohol.type);

        final alcoholLogs =
            logs.where((l) => l.alcoholId == alcohol.id).toList();
        final reviews =
            alcoholLogs.where((l) => l.logKind == LogKind.review).toList();

        double avg = 0.0;
        if (reviews.isNotEmpty) {
          final ratings = reviews.map((r) => r.rating ?? 0.0).toList();
          avg = ratings.reduce((a, b) => a + b) / ratings.length;
        }

        final userLogs =
            alcoholLogs.where((l) => l.userId == user.uid).toList();
        final hasLogged = userLogs.any((l) => l.logKind == LogKind.log);
        final hasReviewed = userLogs.any((l) => l.logKind == LogKind.review);

        items.add(DiscoverItemModel(
          alcohol: alcohol,
          globalRating: avg,
          reviewCount: reviews.length,
          hasUserLogged: hasLogged,
          hasUserReviewed: hasReviewed,
        ));
      }

      // Shuffle initially for random
      items.shuffle();

      if (mounted) {
        setState(() {
          _allAlcohols = items;
          _availableTypes = typesList.toList()..sort();
          _isLoading = false;
        });

        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    var result = List<DiscoverItemModel>.from(_allAlcohols);

    // Apply Text Query
    if (_searchQuery.isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase();
      result = result
          .where((item) =>
              item.alcohol.name.toLowerCase().contains(lowerQuery) ||
              item.alcohol.brand.toLowerCase().contains(lowerQuery) ||
              item.alcohol.type.toLowerCase().contains(lowerQuery) ||
              (item.alcohol.subType?.toLowerCase().contains(lowerQuery) ?? false) ||
              item.alcohol.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)))
          .toList();
    }

    // Apply Type Filter
    if (_selectedType != null) {
      result =
          result.where((item) => item.alcohol.type == _selectedType).toList();
    }

    // Apply Sort
    switch (_selectedSort) {
      case DiscoverSortOption.aToZ:
        result.sort((a, b) => a.alcohol.name.compareTo(b.alcohol.name));
        break;
      case DiscoverSortOption.highestRated:
        result.sort((a, b) => b.globalRating.compareTo(a.globalRating));
        break;
      case DiscoverSortOption.mostReviewed:
        result.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
      case DiscoverSortOption.random:
        // Already shuffled initially. Don't reshuffle to prevent jumpy view.
        break;
    }

    setState(() {
      _filteredAlcohols = result;
    });

    // 🏆 Log analytics if search returns zero results
    if (result.isEmpty && _searchQuery.length > 2) {
      AnalyticsService().logZeroResults(_searchQuery);
    }
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return FilterBottomSheet(
          initialSort: _selectedSort,
          initialType: _selectedType,
          availableTypes: _availableTypes,
          onApply: (sort, type) {
            setState(() {
              _selectedSort = sort;
              _selectedType = type;
            });
            _applyFilters();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            centerTitle: true,
            title: Text('DISCOVER', style: AppTextStyles.appBarTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.bookmark_outline),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WishlistScreen()),
                  );
                },
                tooltip: 'Wishlist',
              ),
            ],
          ),
          if (_isLoading)
            const SliverToBoxAdapter(
              child: _SearchLoadingSkeleton(),
            )
          else if (_error.isNotEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text('Error: $_error',
                    style: AppTextStyles.body.copyWith(color: colorScheme.error)),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                // Search Bar
                child: TextField(
                  controller: _controller,
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    hintText: 'Discover alcohols, brands, types...',
                    prefixIcon:
                        Icon(Icons.search, color: customColors.textMuted),
                    suffixIcon: IconButton(
                      icon: Icon(
                        Icons.tune,
                        color: (_selectedType != null ||
                                _selectedSort !=
                                    DiscoverSortOption.random)
                            ? colorScheme.primary
                            : customColors.textMuted,
                      ),
                      onPressed: _openFilterSheet,
                    ),
                  ),
                  onChanged: (value) {
                    _searchQuery = value.trim();
                    _applyFilters();
                    
                    // 🏆 Log analytics event (only for terms > 2 chars to avoid noise)
                    if (_searchQuery.length > 2) {
                      AnalyticsService().logSearch(_searchQuery);
                    }
                  },
                ),
              ),
            ),
            if (_filteredAlcohols.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppEmptyState(
                  icon: Icons.search_off_outlined,
                  title: 'No results found',
                  subtitle:
                      'Try searching for something else\nor clearing your filters.',
                  buttonText: 'Clear Search',
                  onAddTap: () {
                    _controller.clear();
                    setState(() {
                      _searchQuery = '';
                      _selectedType = null;
                      _selectedSort = DiscoverSortOption.random;
                    });
                    _applyFilters();
                  },
                ),
              )
            else
              SliverPadding(
                padding: AppSpacing.pagePadding.copyWith(top: 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return DiscoverAlcoholCard(
                        item: _filteredAlcohols[index],
                      );
                    },
                    childCount: _filteredAlcohols.length,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
/* ----------------------------- SKELETONS ----------------------------- */

class _SearchLoadingSkeleton extends StatelessWidget {
  const _SearchLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
          child: AppShimmer(height: 56, borderRadius: BorderRadius.circular(AppSpacing.radiusDefault)),
        ),
        ...List.generate(
          6,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg, left: AppSpacing.xl, right: AppSpacing.xl),
            child: AppShimmer(
              height: 100,
              borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
            ),
          ),
        ),
      ],
    );
  }
}
