import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../app/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../drink_logs/models/drink_model_dto.dart';
import '../../drink_logs/providers/drink_logs_provider.dart';
import '../../alcohol/models/alcohol_model.dart';

class StatsScreen extends ConsumerWidget {
  static const routeName = '/stats';
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(drinkLogsProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Taste Identity',
      ),
      body: logsAsync.when(
        loading: () => const _StatsLoadingSkeleton(),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(
              child: Text('Log your first bottle to see your stats!'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _IdentitySection(logs: logs),
              const SizedBox(height: 24),
              _GlobalMetricSection(logs: logs),
              const SizedBox(height: 24),
              _TasteBreakdown(logs: logs),
              const SizedBox(height: 24),
              _ReflectionSection(logs: logs),
              const SizedBox(height: 100),
            ],
          );
        },
      ),
    );
  }
}

class _IdentitySection extends StatelessWidget {
  final List<DrinkLogModel> logs;
  const _IdentitySection({required this.logs});

  @override
  Widget build(BuildContext context) {
    final identity = _deriveIdentity(logs);
    final favoriteSpirit = _getFavoriteCategory(logs);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(Icons.psychology_outlined, size: 48, color: Colors.black),
          const SizedBox(height: 12),
          Text(
            identity.toUpperCase(),
            style: AppTextStyles.title.copyWith(
              color: Colors.black,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Based on your $favoriteSpirit collection",
            style: AppTextStyles.caption.copyWith(
              color: Colors.black.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _deriveIdentity(List<DrinkLogModel> logs) {
    final Map<String, int> counts = {};
    for (var l in logs) {
      counts[l.alcoholType] = (counts[l.alcoholType] ?? 0) + 1;
    }
    final favorite = counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    
    if (logs.length > 20) return "$favorite Connoisseur";
    if (logs.length > 10) return "$favorite Enthusiast";
    return "$favorite Explorer";
  }

  String _getFavoriteCategory(List<DrinkLogModel> logs) {
    final Map<String, int> countMap = {};
    for (final log in logs) {
      countMap[log.alcoholType] = (countMap[log.alcoholType] ?? 0) + 1;
    }
    return countMap.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}

class _GlobalMetricSection extends StatelessWidget {
  final List<DrinkLogModel> logs;
  const _GlobalMetricSection({required this.logs});

  @override
  Widget build(BuildContext context) {
    final uniqueBottles = logs.map((l) => l.alcoholId).toSet().length;
    final nightsRecorded = logs
        .map((l) => DateTime(l.createdAt.year, l.createdAt.month, l.createdAt.day))
        .toSet()
        .length;

    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: "UNIQUE BOTTLES",
            value: uniqueBottles.toString(),
            icon: Icons.local_bar,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            label: "NIGHTS LOGGED",
            value: nightsRecorded.toString(),
            icon: Icons.calendar_today,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: customColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: customColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.amber),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.section.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.bold,
              color: customColors.textMuted,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _TasteBreakdown extends StatelessWidget {
  final List<DrinkLogModel> logs;
  const _TasteBreakdown({required this.logs});

  @override
  Widget build(BuildContext context) {
    final reviewLogs = logs.where((l) => l.rating != null).toList();
    if (reviewLogs.isEmpty) return const SizedBox.shrink();

    final highestRated = reviewLogs.reduce((a, b) => a.rating! > b.rating! ? a : b);
    final customColors = Theme.of(context).extension<AppCustomColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "TOP SELECTION",
          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: customColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black26,
                ),
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('alcohols')
                      .doc(highestRated.alcoholId)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final alcohol = AlcoholModel.fromFirestore(snapshot.data!);
                      return Hero(
                        tag: 'stats_alcohol_${alcohol.id}',
                        child: CachedNetworkImage(
                          imageUrl: alcohol.imageUrl,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const AppShimmer(),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
                      );
                    }
                    return const Icon(Icons.star, color: Colors.amber);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      highestRated.alcoholName,
                      style: AppTextStyles.title,
                    ),
                    Text(
                      "Your highest rated bottle",
                      style: AppTextStyles.caption.copyWith(color: customColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < highestRated.rating!.round()
                              ? Icons.star
                              : Icons.star_border,
                          size: 14,
                          color: Colors.amber,
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReflectionSection extends StatelessWidget {
  final List<DrinkLogModel> logs;
  const _ReflectionSection({required this.logs});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "CHRONICLES",
          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        const SizedBox(height: 12),
        _StatTile(
          label: "Total Entries Recorded",
          value: logs.length.toString(),
          icon: Icons.history_edu,
        ),
        _StatTile(
          label: "Most Active Night",
          value: _getMostActiveDay(logs),
          icon: Icons.nights_stay,
        ),
      ],
    );
  }

  String _getMostActiveDay(List<DrinkLogModel> logs) {
    final Map<int, int> weekdayCounts = {};
    for (var l in logs) {
      weekdayCounts[l.createdAt.weekday] = (weekdayCounts[l.createdAt.weekday] ?? 0) + 1;
    }
    if (weekdayCounts.isEmpty) return "None";
    final mostActive = weekdayCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    const days = ["", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
    return days[mostActive];
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Colors.amber),
          ),
          const SizedBox(width: 16),
          Text(label, style: AppTextStyles.body.copyWith(color: Colors.white70)),
          const Spacer(),
          Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}
/* ----------------------------- SKELETONS ----------------------------- */

class _StatsLoadingSkeleton extends StatelessWidget {
  const _StatsLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        AppShimmer(height: 120, borderRadius: BorderRadius.all(Radius.circular(24))),
        SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: AppShimmer(height: 100, borderRadius: BorderRadius.all(Radius.circular(20)))),
            SizedBox(width: 12),
            Expanded(child: AppShimmer(height: 100, borderRadius: BorderRadius.all(Radius.circular(20)))),
          ],
        ),
        SizedBox(height: 24),
        AppShimmer(width: 100, height: 12),
        SizedBox(height: 12),
        AppShimmer(height: 110, borderRadius: BorderRadius.all(Radius.circular(20))),
        SizedBox(height: 24),
        AppShimmer(width: 100, height: 12),
        SizedBox(height: 12),
        AppShimmer(height: 48, borderRadius: BorderRadius.all(Radius.circular(12))),
        SizedBox(height: 12),
        AppShimmer(height: 48, borderRadius: BorderRadius.all(Radius.circular(12))),
      ],
    );
  }
}
