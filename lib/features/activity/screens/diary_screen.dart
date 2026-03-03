import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drunk_diary/features/drink_logs/models/drink_model_dto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../drink_logs/widgets/drink_log_card.dart';
import '../../drink_logs/widgets/log_detail_bottom_sheet.dart';
import '../../alcohol/models/alcohol_model.dart';
import '../../../core/widgets/app_empty_state.dart';
import 'package:drunk_diary/core/navigation/tab_change_notification.dart';

enum DiaryLayout { timeline, gallery }

class DiaryScreen extends StatefulWidget {
  static const routeName = '/diary';
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  String _selectedFilter = 'All';
  DiaryLayout _currentLayout = DiaryLayout.timeline;

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('drink_logs')
              .where('userId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allLogs = snapshot.hasData
                ? snapshot.data!.docs
                    .map((doc) => DrinkLogModel.fromFirestore(doc))
                    .toList()
                : <DrinkLogModel>[];

            final logs = allLogs.where((log) {
              if (_selectedFilter == 'All') return true;
              if (_selectedFilter == 'Logs') return log.logKind == LogKind.log;
              if (_selectedFilter == 'Reviews') {
                return log.logKind == LogKind.review;
              }
              return true;
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Header(),
                const SizedBox(height: 12),
                _StatsRow(logs: allLogs),
                const SizedBox(height: 16),
                _FiltersRow(
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
                const SizedBox(height: 8),
                Expanded(
                  child: _DiaryList(
                    logs: logs,
                    layout: _currentLayout,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/* ----------------------------- HEADER ----------------------------- */

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Your Diary',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.amber,
            child: const Icon(Icons.person, color: Colors.black),
          ),
        ],
      ),
    );
  }
}

/* ----------------------------- STATS ----------------------------- */

class _StatsRow extends StatelessWidget {
  final List<DrinkLogModel> logs;
  const _StatsRow({required this.logs});

  @override
  Widget build(BuildContext context) {
    final total = logs.where((l) => l.logKind == LogKind.log).length;

    final reviewLogs = logs
        .where((l) => l.logKind == LogKind.review && l.rating != null)
        .toList();
    final double? avgRating = reviewLogs.isEmpty
        ? null
        : reviewLogs.map((l) => l.rating!).reduce((a, b) => a + b) /
            reviewLogs.length;

    final favorite = _getFavoriteCategory(logs);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              title: 'Total',
              value: total.toString(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              title: 'Avg Rating',
              value: avgRating == null ? '—' : avgRating.toStringAsFixed(1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              title: 'Favorite',
              value: favorite ?? '—',
            ),
          ),
        ],
      ),
    );
  }

  String? _getFavoriteCategory(List<DrinkLogModel> logs) {
    final Map<String, int> countMap = {};

    for (final log in logs) {
      countMap[log.alcoholType] = (countMap[log.alcoholType] ?? 0) + 1;
    }

    if (countMap.isEmpty) return null;

    return countMap.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            selected: selectedFilter == 'All',
            onTap: () => onFilterChanged('All'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Logs',
            selected: selectedFilter == 'Logs',
            onTap: () => onFilterChanged('Logs'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Reviews',
            selected: selectedFilter == 'Reviews',
            onTap: () => onFilterChanged('Reviews'),
          ),
          const Spacer(),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.amber : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: selected ? Colors.amber : Colors.grey.shade700),
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

/* ----------------------------- DIARY ----------------------------- */

class _DiaryList extends StatelessWidget {
  final List<DrinkLogModel> logs;
  final DiaryLayout layout;

  const _DiaryList({
    required this.logs,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return AppEmptyState(
        icon: Icons.history_edu_outlined,
        title: 'Your diary is empty',
        subtitle: 'Capture your first drink memory\nand see it here.',
        buttonText: 'Log a Drink',
        onAddTap: () {
          const TabChangeNotification(2).dispatch(context);
        },
      );
    }

    if (layout == DiaryLayout.gallery) {
      return GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: logs.length,
        itemBuilder: (context, index) {
          return _GalleryItem(log: logs[index]);
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        return DrinkLogCard(log: logs[index]);
      },
    );
  }
}

class _GalleryItem extends StatelessWidget {
  final DrinkLogModel log;
  const _GalleryItem({required this.log});

  @override
  Widget build(BuildContext context) {
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
          color: Colors.grey.shade900,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: log.photoUrl != null && log.photoUrl!.isNotEmpty
                  ? Image.network(
                      log.photoUrl!,
                      fit: BoxFit.cover,
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
                          return Image.network(
                            alcohol.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade800,
                              child: const Icon(Icons.local_bar,
                                  color: Colors.white24),
                            ),
                          );
                        }
                        return Container(
                          color: Colors.grey.shade800,
                          child:
                              const Center(child: CircularProgressIndicator()),
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
