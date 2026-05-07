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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../profile/screens/profile_screen.dart';
import '../../profile/widgets/user_search_tile.dart';
import '../providers/discover_search_provider.dart';
import '../widgets/search_result_section.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _alcoholRepo = AlcoholRepository();

  bool _isLoading = true;
  String _error = '';

  List<DiscoverItemModel> _allAlcohols = [];
  List<DiscoverItemModel> _filteredAlcohols = [];
  List<String> _availableTypes = [];

  // Filter & Sort State (Used for default discovery)
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
      
      // Also fetch current user's logs
      final myLogsSnapshot = await FirebaseFirestore.instance.collection('drink_logs')
          .where('userId', isEqualTo: user.uid)
          .get();

      final rawLogs = [
        ...logsSnapshot.docs.map(DrinkLogModel.fromFirestore),
        ...myLogsSnapshot.docs.map(DrinkLogModel.fromFirestore),
      ];

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

    if (_selectedType != null) {
      result =
          result.where((item) => item.alcohol.type == _selectedType).toList();
    }

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
        break;
    }

    setState(() {
      _filteredAlcohols = result;
    });
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
    final searchState = ref.watch(discoverSearchProvider);

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
          
          // Unified Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
              child: TextField(
                controller: _controller,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  hintText: 'Search bottles or people',
                  prefixIcon:
                      Icon(Icons.search, color: customColors.textMuted),
                  suffixIcon: _controller.text.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _controller.clear();
                          ref.read(searchQueryControllerProvider).add('');
                        },
                      )
                    : IconButton(
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
                  ref.read(searchQueryControllerProvider).add(value);
                },
              ),
            ),
          ),

          if (searchState.showResults)
            ..._buildSearchResults(searchState)
          else if (_isLoading)
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
          else
            _buildDiscoveryFeed(),
        ],
      ),
    );
  }

  List<Widget> _buildSearchResults(DiscoverSearchState state) {
    if (state.isSearching) {
      return [
        const SliverToBoxAdapter(child: _SearchLoadingSkeleton()),
      ];
    }

    if (state.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyState(
            icon: Icons.search_off_outlined,
            title: 'No people or bottles found',
            subtitle: 'Try searching for something else.',
            buttonText: 'Clear Search',
            onAddTap: () {
              _controller.clear();
              ref.read(searchQueryControllerProvider).add('');
            },
          ),
        ),
      ];
    }

    // Smart Ordering: Whichever section has the highest score match appears first
    final topPeopleScore = state.peopleResults.isEmpty ? 0 : state.peopleResults.first.score;
    final topBottleScore = state.bottleResults.isEmpty ? 0 : state.bottleResults.first.score;

    final List<Widget> sections = [];

    final peopleSection = SliverToBoxAdapter(
      child: SearchResultSection(
        title: 'People',
        children: state.peopleResults.map((res) => UserSearchTile(
          user: res.user,
          onTap: () {
             Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(userId: res.user.id),
              ),
            );
          },
        )).toList(),
      ),
    );

    final bottleSection = SliverPadding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == 0) {
              return SearchResultSection(
                title: 'Bottles',
                children: const [], // Section header is handled by wrapper
              );
            }
            // We wrap the list in a single SliverList, but need a header
            // Actually let's use SearchResultSection for the header and then the list
            return const SizedBox.shrink();
          },
          childCount: 1,
        ),
      ),
    );

    // Re-evaluating section building for Sliver compatibility
    final List<Widget> resultSlivers = [];

    if (topPeopleScore >= topBottleScore) {
      if (state.peopleResults.isNotEmpty) resultSlivers.add(peopleSection);
      if (state.bottleResults.isNotEmpty) {
        resultSlivers.add(SliverToBoxAdapter(child: SearchResultSection(title: 'Bottles', children: const [])));
        resultSlivers.add(_buildBottleResultsList(state));
      }
    } else {
      if (state.bottleResults.isNotEmpty) {
        resultSlivers.add(SliverToBoxAdapter(child: SearchResultSection(title: 'Bottles', children: const [])));
        resultSlivers.add(_buildBottleResultsList(state));
      }
      if (state.peopleResults.isNotEmpty) resultSlivers.add(peopleSection);
    }

    return resultSlivers;
  }

  Widget _buildBottleResultsList(DiscoverSearchState state) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final alcohol = state.bottleResults[index].alcohol;
            // Map to DiscoverItemModel for consistent UI
            // In a real app, this should be cached or fetched properly
            final item = DiscoverItemModel(
              alcohol: alcohol,
              globalRating: 0,
              reviewCount: 0,
              hasUserLogged: false,
              hasUserReviewed: false,
            );
            return DiscoverAlcoholCard(item: item);
          },
          childCount: state.bottleResults.length,
        ),
      ),
    );
  }

  Widget _buildDiscoveryFeed() {
    if (_filteredAlcohols.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: AppEmptyState(
          icon: Icons.wine_bar_outlined,
          title: 'Nothing here yet',
          subtitle: 'Try adjusting your filters.',
          buttonText: 'Reset Filters',
          onAddTap: () {
            setState(() {
              _selectedType = null;
              _selectedSort = DiscoverSortOption.random;
            });
            _applyFilters();
          },
        ),
      );
    }

    return SliverPadding(
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
