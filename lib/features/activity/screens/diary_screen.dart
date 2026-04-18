import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drunk_diary/features/drink_logs/models/drink_model_dto.dart';
import 'package:flutter/material.dart';

import '../../drink_logs/widgets/drink_log_card.dart';
import '../../drink_logs/widgets/log_detail_bottom_sheet.dart';
import '../../alcohol/models/alcohol_model.dart';
import '../../../core/widgets/app_empty_state.dart';
import 'package:drunk_diary/core/navigation/tab_change_notification.dart';
import '../../../app/app_theme.dart';
import 'package:drunk_diary/features/drink_logs/providers/drink_logs_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_constants.dart';

enum DiaryLayout { timeline, gallery }

class DiaryScreen extends ConsumerStatefulWidget {
  static const routeName = '/diary';
  const DiaryScreen({super.key});

  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  String _selectedFilter = 'All';
  DiaryLayout _currentLayout = DiaryLayout.timeline;

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(drinkLogsProvider);

    return SafeArea(
      child: logsAsync.when(
        loading: () => Scaffold(
          body: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                centerTitle: true,
                title: SvgPicture.asset(
                  'assets/icons/drunk_diary_logo.svg',
                  height: APP_BAR_VISUAL_HEIGHT,
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.bar_chart),
                    onPressed: () => Navigator.pushNamed(context, '/stats'),
                    tooltip: 'View Stats',
                  ),
                ],
              ),
              const SliverToBoxAdapter(child: _WelcomeSectionSkeleton()),
              const SliverToBoxAdapter(child: SizedBox(height: 36)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Row(
                    children: [
                      AppShimmer(width: 100, height: 36, borderRadius: BorderRadius.circular(20)),
                      const SizedBox(width: AppSpacing.sm),
                      AppShimmer(width: 80, height: 36, borderRadius: BorderRadius.circular(20)),
                      const SizedBox(width: AppSpacing.sm),
                      AppShimmer(width: 110, height: 36, borderRadius: BorderRadius.circular(20)),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
              _DiarySliverListSkeleton(layout: _currentLayout),
            ],
          ),
        ),
        error: (err, stack) => Scaffold(
          body: Center(child: Text('Error: $err')),
        ),
        data: (allLogs) {
          final logs = allLogs.where((log) {
            if (_selectedFilter == 'All') return true;
            if (_selectedFilter == 'Logs') return log.logKind == LogKind.log;
            if (_selectedFilter == 'Reviews') {
              return log.logKind == LogKind.review;
            }
            return true;
          }).toList();

          return Scaffold(
            floatingActionButton: allLogs.isEmpty
                ? null
                : FloatingActionButton.extended(
                    onPressed: () {
                      const TabChangeNotification(2).dispatch(context);
                    },
                    icon: const Icon(Icons.add, color: Colors.black),
                    label: const Text('Log a Drink',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                    backgroundColor: Colors.amber,
                    heroTag: 'diary_fab',
                  ),
            body: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                SliverAppBar(
                  floating: true,
                  snap: true,
                  centerTitle: true,
                  title: SvgPicture.asset(
                    'assets/icons/drunk_diary_logo.svg',
                    height: APP_BAR_VISUAL_HEIGHT,
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.bar_chart),
                      onPressed: () => Navigator.pushNamed(context, '/stats'),
                      tooltip: 'View Stats',
                    ),
                  ],
                ),
                const SliverToBoxAdapter(child: _WelcomeSection()),
                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)), // 16 (section padding) + 8 = 24 total gap
                SliverToBoxAdapter(
                  child: _FiltersRow(
                    selectedFilter: _selectedFilter,
                    currentLayout: _currentLayout,
                    onFilterChanged: (filter) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    onLayoutChanged: (layout) {
                      setState(() {
                        _currentLayout = layout;
                      });
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
                _DiarySliverList(
                  logs: logs,
                  layout: _currentLayout,
                ),
                // FAB naturally floats above the list, no need for large bottom padding
                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.hero)),
              ],
            ),
          );
        },
      ),
    );
  }
}

/* ----------------------------- WELCOME SECTION ----------------------------- */

class _WelcomeSection extends StatefulWidget {
  const _WelcomeSection();

  @override
  State<_WelcomeSection> createState() => _WelcomeSectionState();
}

class _WelcomeSectionState extends State<_WelcomeSection> {
  late String _greeting;

  final List<String> _morningGreetings = [
    'Coffee or a breakfast brew?',
    'What\'s the early pour?',
    'Ready for the day\'s first log?',
    'Morning! Starting fresh?',
    'The morning after?',
    'Hydration (with flavor)?',
    'A little \'hair of the dog\'?',
    'Quiet morning, loud bottle.',
  ];

  final List<String> _afternoonGreetings = [
    'What are we drinking?',
    'Found anything new?',
    'A midday refreshment?',
    'Time to log a memory?',
    'Is it 5 PM yet?',
    'A sip of sophistication?',
    'Whatever floats your bottle.',
    'Sip happens.',
    'Found a liquid treasure?',
  ];

  final List<String> _eveningGreetings = [
    'Recording a night to remember?',
    'What\'s the poison tonight?',
    'Sipping on something special?',
    'Ready for another round?',
    'Working on your collection?',
    'Blurry nights, clear memories?',
    'Drunk on life, or just Gin?',
    'Tasting notes: Liquid regret?',
    'Another day, another pour.',
    'Sip, log, repeat.',
    'Fuel for the story.',
    'A toast to the moon.',
    'Sipping with style.',
    'Your cabinet is calling.',
  ];

  @override
  void initState() {
    super.initState();
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = _morningGreetings[Random().nextInt(_morningGreetings.length)];
    } else if (hour < 17) {
      _greeting = _afternoonGreetings[Random().nextInt(_afternoonGreetings.length)];
    } else {
      _greeting = _eveningGreetings[Random().nextInt(_eveningGreetings.length)];
    }
  }

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _greeting,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'GiveYouGlory',
                    fontSize: 32,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


/* ----------------------------- FILTERS ----------------------------- */

class _FiltersRow extends StatelessWidget {
  final String selectedFilter;
  final DiaryLayout currentLayout;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<DiaryLayout> onLayoutChanged;

  const _FiltersRow({
    required this.selectedFilter,
    required this.currentLayout,
    required this.onFilterChanged,
    required this.onLayoutChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All Activity',
                    selected: selectedFilter == 'All',
                    onTap: () => onFilterChanged('All'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _FilterChip(
                    label: 'Your Logs',
                    selected: selectedFilter == 'Logs',
                    onTap: () => onFilterChanged('Logs'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _FilterChip(
                    label: 'Your Reviews',
                    selected: selectedFilter == 'Reviews',
                    onTap: () => onFilterChanged('Reviews'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            onPressed: () {
              onLayoutChanged(
                currentLayout == DiaryLayout.timeline
                    ? DiaryLayout.gallery
                    : DiaryLayout.timeline,
              );
            },
            icon: Icon(
              currentLayout == DiaryLayout.timeline
                  ? Icons.grid_view
                  : Icons.view_agenda_outlined,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? Colors.amber : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
          border:
              Border.all(color: selected ? Colors.amber : customColors.borderDark),
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: selected ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}

/* ----------------------------- DIARY SLIVERS ----------------------------- */

class _DiarySliverList extends StatelessWidget {
  final List<DrinkLogModel> logs;
  final DiaryLayout layout;

  const _DiarySliverList({
    required this.logs,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: AppEmptyState(
          icon: Icons.history_edu_outlined,
          title: 'Your diary is empty',
          subtitle: 'Capture your first drink memory\nand see it here.',
          buttonText: 'Log a Drink',
          onAddTap: () {
            const TabChangeNotification(2).dispatch(context);
          },
        ),
      );
    }

    if (layout == DiaryLayout.gallery) {
      return SliverPadding(
        padding: AppSpacing.pagePadding.copyWith(top: 0),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.lg,
            mainAxisSpacing: AppSpacing.lg,
            childAspectRatio: 0.85,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _GalleryItem(log: logs[index]),
            childCount: logs.length,
          ),
        ),
      );
    }

    // Group logs by date
    final groupedLogs = _groupLogsByDate(logs);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = groupedLogs[index];
          if (item is String) {
            return _DateHeader(dateLabel: item);
          } else {
            return DrinkLogCard(log: item as DrinkLogModel);
          }
        },
        childCount: groupedLogs.length,
      ),
    );
  }

  List<Object> _groupLogsByDate(List<DrinkLogModel> logs) {
    final List<Object> items = [];
    String? lastDate;

    for (final log in logs) {
      final dateLabel = _formatHeaderDate(log.createdAt);
      if (dateLabel != lastDate) {
        items.add(dateLabel);
        lastDate = dateLabel;
      }
      items.add(log);
    }
    return items;
  }

  String _formatHeaderDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return "Today";
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return "Yesterday";
    }

    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}

class _DateHeader extends StatelessWidget {
  final String dateLabel;
  const _DateHeader({required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxl, AppSpacing.lg, AppSpacing.sm),
      child: Text(
        dateLabel.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: customColors.textMuted,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}

class _GalleryItem extends StatelessWidget {
  final DrinkLogModel log;
  const _GalleryItem({required this.log});

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    return GestureDetector(
      onTap: () {
        // reuse same detail view as card
        showModalBottomSheet(
          context: context,
          useSafeArea: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => LogDetailBottomSheet(log: log),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
          color: Theme.of(context).colorScheme.surface,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: log.photoUrl != null && log.photoUrl!.isNotEmpty
                  ? Hero(
                      tag: 'alcohol_${log.id}_photo',
                      child: CachedNetworkImage(
                        imageUrl: log.photoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const AppShimmer(),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ),
                    )
                  : FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('alcohols')
                          .doc(log.alcoholId)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final alcohol =
                              AlcoholModel.fromFirestore(snapshot.data!);
                          return Hero(
                            tag: 'alcohol_log_${log.id}',
                            child: CachedNetworkImage(
                              imageUrl: alcohol.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const AppShimmer(),
                              errorWidget: (context, url, error) => Container(
                                color: customColors.borderDark,
                                child: const Icon(Icons.local_bar,
                                    color: Colors.white24),
                              ),
                            ),
                          );
                        }
                        return Container(
                          color: customColors.borderDark,
                          child:
                              const Center(child: AppShimmer()),
                        );
                      },
                    ),
            ),

            // Gradient Overlay for visibility
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.4),
                    ],
                  ),
                ),
              ),
            ),
            // Title at bottom
            Positioned(
              bottom: 8,
              left: 12,
              right: 12,
              child: Text(
                log.alcoholName,
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
/* ----------------------------- SKELETONS ----------------------------- */

class _WelcomeSectionSkeleton extends StatelessWidget {
  const _WelcomeSectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppShimmer(width: 250, height: 36, borderRadius: BorderRadius.all(Radius.circular(12))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiarySliverListSkeleton extends StatelessWidget {
  final DiaryLayout layout;
  const _DiarySliverListSkeleton({required this.layout});

  @override
  Widget build(BuildContext context) {
    if (layout == DiaryLayout.gallery) {
      return SliverPadding(
        padding: AppSpacing.pagePadding.copyWith(top: 0),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.lg,
            mainAxisSpacing: AppSpacing.lg,
            childAspectRatio: 0.85,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => AppShimmer(
              borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
              height: double.infinity,
            ),
            childCount: 6,
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index % 4 == 0) {
            return const Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxl, AppSpacing.lg, AppSpacing.sm),
              child: AppShimmer(width: 80, height: 12),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: AppShimmer(
              height: 140,
              borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
            ),
          );
        },
        childCount: 10,
      ),
    );
  }
}
