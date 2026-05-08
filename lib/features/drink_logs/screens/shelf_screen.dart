import 'dart:math';
import 'package:flutter/material.dart';
import '../../../app/app_theme.dart';
import '../../alcohol/models/alcohol_model.dart';
import '../widgets/shelf_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import 'package:drunk_diary/core/navigation/tab_change_notification.dart';
import 'package:drunk_diary/features/drink_logs/providers/drink_logs_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/responsive_tokens.dart';
import '../../../core/theme/app_typography_roles.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/responsive_layout.dart';

class ShelfScreen extends ConsumerStatefulWidget {
  static const routeName = '/shelf';
  const ShelfScreen({super.key});

  @override
  ConsumerState<ShelfScreen> createState() => _ShelfScreenState();
}

class _ShelfScreenState extends ConsumerState<ShelfScreen> {
  // For Filtering & Sorting
  String searchQuery = '';
  String selectedSort = 'Recent'; // 'Recent', 'Rating', 'Name', 'ABV%'

  @override
  Widget build(BuildContext context) {
    final shelfAsync = ref.watch(shelfAlcoholsProvider);

    return shelfAsync.when(
      loading: () => const _ShelfLoadingSkeleton(),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Error: $err')),
      ),
      data: (items) {
        // items is List<Map<String, dynamic>> where each map has:
        // 'alcohol': AlcoholModel, 'logCount': int, 'avgRating': double, 'lastInteraction': DateTime

        // 1. Filter by search query
        List<Map<String, dynamic>> filtered = items.where((item) {
          final alcohol = item['alcohol'] as AlcoholModel;
          if (searchQuery.isNotEmpty) {
            if (!alcohol.name.toLowerCase().contains(searchQuery.toLowerCase())) {
              return false;
            }
          }
          return true;
        }).toList();

        // 2. Sort
        filtered.sort((a, b) {
          if (selectedSort == 'Rating') {
            return (b['avgRating'] as double).compareTo(a['avgRating'] as double);
          } else if (selectedSort == 'Name') {
            final alcoholA = a['alcohol'] as AlcoholModel;
            final alcoholB = b['alcohol'] as AlcoholModel;
            return alcoholA.name.compareTo(alcoholB.name);
          } else if (selectedSort == 'ABV%') {
            final alcoholA = a['alcohol'] as AlcoholModel;
            final alcoholB = b['alcohol'] as AlcoholModel;
            return alcoholB.abv.compareTo(alcoholA.abv);
          } else {
            // Recent
            final dateA = a['lastInteraction'] as DateTime;
            final dateB = b['lastInteraction'] as DateTime;
            return dateB.compareTo(dateA);
          }
        });

        return _buildShelfView(context, items.map((e) => e['alcohol'] as AlcoholModel).toList(), filtered);
      },
    );
  }

  Widget _buildShelfView(BuildContext context, List<AlcoholModel> allShelfAlcohols, List<Map<String, dynamic>> displayItems) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // For the glowing shelves
    final List<Color> glowColors = [
      colorScheme.primary, // amber
      Colors.pinkAccent,
      Colors.blueAccent,
      Colors.greenAccent,
    ];

    // Calculate items per shelf based on screen width
    final itemsPerShelf = context.responsiveValue<int>(mobile: 3, tablet: 4, desktop: 5);

    // Chunk list by itemsPerShelf
    List<List<Map<String, dynamic>>> shelves = [];
    for (var i = 0; i < displayItems.length; i += itemsPerShelf) {
      shelves.add(displayItems.sublist(i, min(i + itemsPerShelf, displayItems.length)));
    }

    return Scaffold(
      body: ResponsiveScaffoldBody(
        maxWidth: AppWidths.grid,
        padding: EdgeInsets.zero,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              centerTitle: true,
              title: Text('SHELF', style: AppTypography.appBarTitle(context)),
            ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Text("${allShelfAlcohols.length} bottles in collection",
                      style: textTheme.bodyMedium?.copyWith(
                          color: customColors.textMuted)),
                ),
                // Top Search & Sorts
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                  child: TextField(
                      style: textTheme.bodyMedium,
                      decoration: InputDecoration(
                          hintText: "Search your collection...",
                          hintStyle: textTheme.bodyMedium
                              ?.copyWith(color: customColors.textMuted),
                          prefixIcon: Icon(Icons.search, color: customColors.textMuted),
                          filled: true,
                          fillColor: customColors.cardBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.all(AppSpacing.lg)),
                      onChanged: (val) {
                        setState(() {
                          searchQuery = val;
                        });
                      }),
                ),
                SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                    child: Row(children: [
                      _sortChip(context, 'Recent'),
                      const SizedBox(width: AppSpacing.sm),
                      _sortChip(context, 'Rating'),
                      const SizedBox(width: AppSpacing.sm),
                      _sortChip(context, 'Name'),
                      const SizedBox(width: AppSpacing.sm),
                      _sortChip(context, 'ABV%'),
                    ])),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),

          // Main Shelf View
          if (shelves.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: AppEmptyState(
                icon: Icons.inventory_2_outlined,
                title: allShelfAlcohols.isEmpty
                    ? 'Your shelf is empty'
                    : 'No matches found',
                subtitle: allShelfAlcohols.isEmpty
                    ? 'Log your first drink to start building\nyour personal collection.'
                    : 'Try searching for something else\nor clearing your filters.',
                buttonText: allShelfAlcohols.isEmpty
                    ? 'Discover Drinks'
                    : 'Clear Search',
                onAddTap: () {
                  if (allShelfAlcohols.isEmpty) {
                    // Dispatch notification to jump to Search tab
                    const TabChangeNotification(2).dispatch(context);
                  } else {
                    setState(() {
                      searchQuery = '';
                    });
                  }
                },
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final chunk = shelves[index];
                    final Color glow = glowColors[index % glowColors.length];

                    return Column(children: [
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: chunk.map((item) {
                              final alcohol = item['alcohol'] as AlcoholModel;
                              return Expanded(
                                  child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.md),
                                      child: ShelfCard(
                                        alcohol: alcohol,
                                        logCount: item['logCount'] as int,
                                        avgRating: item['avgRating'] as double,
                                      )));
                            }).toList()
                              ..addAll(List.generate(
                                  itemsPerShelf - chunk.length,
                                  (_) => const Expanded(
                                      child: SizedBox()))),
                          )),
                      const SizedBox(height: AppSpacing.sm),

                      // Glowing Shelf Divider
                      Container(
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                        decoration: BoxDecoration(
                            color: customColors.borderDark,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.onSurface.withOpacity(0.1),
                                blurRadius: 1,
                                offset: const Offset(0, -1),
                              ),
                              BoxShadow(
                                color: glow.withOpacity(0.8),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                              BoxShadow(
                                color: glow.withOpacity(0.4),
                                blurRadius: 25,
                                offset: const Offset(0, 8),
                              )
                            ],
                            gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  customColors.cardBackground,
                                  customColors.deepCardBackground
                                ])),
                      ),
                      const SizedBox(height: AppSpacing.hero),
                    ]);
                  },
                  childCount: shelves.length,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

  Widget _sortChip(BuildContext context, String title) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = selectedSort == title;
    return GestureDetector(
        onTap: () => setState(() => selectedSort = title),
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.primary : Colors.transparent,
              border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : customColors.borderDark),
              borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
            ),
            child: Text(title,
                style: TextStyle(
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface.withOpacity(0.7),
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w500))));
  }
}
/* ----------------------------- SKELETONS ----------------------------- */

class _ShelfLoadingSkeleton extends StatelessWidget {
  const _ShelfLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            centerTitle: true,
            title: Text('SHELF', style: AppTextStyles.appBarTitle),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: AppShimmer(height: 48, borderRadius: BorderRadius.circular(12)),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      AppShimmer(width: 80, height: 36, borderRadius: BorderRadius.all(Radius.circular(20))),
                      SizedBox(width: 8),
                      AppShimmer(width: 80, height: 36, borderRadius: BorderRadius.all(Radius.circular(20))),
                      SizedBox(width: 8),
                      AppShimmer(width: 80, height: 36, borderRadius: BorderRadius.all(Radius.circular(20))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Container(
                  margin: const EdgeInsets.only(bottom: 80),
                  child: const Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(child: _ShelfCardSkeleton()),
                          SizedBox(width: 32),
                          Expanded(child: _ShelfCardSkeleton()),
                          SizedBox(width: 32),
                          Expanded(child: _ShelfCardSkeleton()),
                        ],
                      ),
                      SizedBox(height: 8),
                      AppShimmer(height: 8, borderRadius: BorderRadius.all(Radius.circular(4))),
                    ],
                  ),
                ),
                childCount: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShelfCardSkeleton extends StatelessWidget {
  const _ShelfCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AppShimmer(height: 100, borderRadius: BorderRadius.all(Radius.circular(12))),
        SizedBox(height: 8),
        AppShimmer(height: 12, width: 40),
      ],
    );
  }
}
