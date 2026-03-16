import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drunk_diary/features/drink_logs/models/drink_model_dto.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
            slivers: [
              const SliverToBoxAdapter(child: _WelcomeSectionSkeleton()),
              const SliverToBoxAdapter(child: SizedBox(height: 36)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      AppShimmer(width: 100, height: 36, borderRadius: BorderRadius.circular(20)),
                      const SizedBox(width: 8),
                      AppShimmer(width: 80, height: 36, borderRadius: BorderRadius.circular(20)),
                      const SizedBox(width: 8),
                      AppShimmer(width: 110, height: 36, borderRadius: BorderRadius.circular(20)),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
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
                  ),
            body: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: _WelcomeSection()),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
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
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                _DiarySliverList(
                  logs: logs,
                  layout: _currentLayout,
                ),
                const SliverToBoxAdapter(
                    child: SizedBox(height: 100)), // Space for FAB
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
  ];

  final List<String> _afternoonGreetings = [
    'What are we drinking?',
    'Found anything new?',
    'A midday refreshment?',
    'Time to log a memory?',
  ];

  final List<String> _eveningGreetings = [
    'Recording a night to remember?',
    'What\'s the poison tonight?',
    'Sipping on something special?',
    'Ready for another round?',
    'Working on your collection?',
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
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.split(' ').first ?? 'Friend';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.amber.withOpacity(0.1),
            backgroundImage: user?.photoURL != null
                ? NetworkImage(user!.photoURL!)
                : null,
            child: user?.photoURL == null
                ? const Icon(Icons.person_outline, color: Colors.amber, size: 28)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hey $displayName! 👋",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 1),
                Text(
                  _greeting,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.8,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/stats'),
            icon: const Icon(Icons.auto_graph, color: Colors.amber, size: 20),
            tooltip: 'View Stats',
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Your Logs',
                    selected: selectedFilter == 'Logs',
                    onTap: () => onFilterChanged('Logs'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Your Reviews',
                    selected: selectedFilter == 'Reviews',
                    onTap: () => onFilterChanged('Reviews'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.amber : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: selected ? Colors.amber : customColors.borderDark),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white,
            fontWeight: FontWeight.w500,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
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
    final textTheme = Theme.of(context).textTheme;
    final customColors = Theme.of(context).extension<AppCustomColors>()!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 16, 8),
      child: Text(
        dateLabel.toUpperCase(),
        style: textTheme.labelMedium?.copyWith(
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
          borderRadius: BorderRadius.circular(20),
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
                            tag: 'alcohol_${alcohol.id}',
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
                      Colors.black.withOpacity(0.4),
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
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
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
      padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          AppShimmer.circular(size: 56),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppShimmer(width: 120, height: 16),
                SizedBox(height: 8),
                AppShimmer(width: 200, height: 28),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => AppShimmer(
              borderRadius: BorderRadius.circular(20),
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
              padding: EdgeInsets.fromLTRB(20, 24, 16, 8),
              child: AppShimmer(width: 80, height: 12),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: AppShimmer(
              height: 140,
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
        childCount: 10,
      ),
    );
  }
}
