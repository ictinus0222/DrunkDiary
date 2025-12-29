import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../drink_logs/repositories/drink_log_repository.dart';
import '../models/alcohol_model.dart';
import '../../drink_logs/models/drink_log_model.dart';
import '../../drink_logs/widgets/create_log_bottom_sheet.dart';
import '../../drink_logs/widgets/drink_log_card.dart';
import '../widgets/public_log_tile.dart';

class AlcoholDetailScreen extends StatelessWidget {
  final AlcoholModel alcohol;

  const AlcoholDetailScreen({
    super.key,
    required this.alcohol,
  });

  Stream<List<DrinkLogModel>> _logsStream() {
    final user = FirebaseAuth.instance.currentUser!;

    // Gets all logs by THIS user for THIS alcohol, newest first.
    return FirebaseFirestore.instance
        .collection('drink_logs')
        .where('userId', isEqualTo: user.uid)
        .where('alcoholId', isEqualTo: alcohol.id)
        .orderBy('createdAt', descending: true)
        .snapshots()
        // Firestore docs -> DrinkLogModel
        // UI only gets clean Dart objects
        .map(
          (snapshot) =>
          snapshot.docs.map(DrinkLogModel.fromFirestore).toList(),
    );
  }

  Future<(int, double)> _fetchGlobalStats() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('drink_logs')
        .where('alcoholId', isEqualTo: alcohol.id)
        .where('visibility', isEqualTo: 'public') // important
        .get();

    final docs = snapshot.docs;

    if (docs.isEmpty) return (0, 0.0);

    final ratings = docs
        .map((doc) => (doc['rating'] as num).toDouble())
        .toList();

    final avgRating =
        ratings.reduce((a, b) => a + b) / ratings.length;

    return (docs.length, avgRating);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(alcohol.name)),
      body: StreamBuilder<List<DrinkLogModel>>( // Handles live refresh after logging
        stream: _logsStream(),
        builder: (context, snapshot) {
          final logs = snapshot.data ?? []; // if data hasn't arrived yet, empty list

          final logCount = logs.length; // number of times a drink is logged

          final double avgRating = logs.isEmpty
              ? 0
              : logs
              .map((l) => l.rating)
              .reduce((a, b) => a + b) /
              logs.length.toDouble();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _AlcoholHeader(alcohol: alcohol),

              const SizedBox(height: 16),

              FutureBuilder<(int, double)>(
                future: _fetchGlobalStats(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    );
                  }

                  final (logCount, avgRating) = snapshot.data!;

                  return _AlcoholStats(
                    logCount: logCount,
                    avgRating: avgRating,
                  );
                },
              ),


              const SizedBox(height: 16),

              const Text(
                'Your logs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              ...logs.map((log) => DrinkLogCard(log: log)),

              const SizedBox(height: 24),
              Text(
                'Community',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              FutureBuilder<List<DrinkLogModel>>(
                future: fetchPublicLogsForAlcohol(alcohol.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No public logs yet. Be the first to log this drink.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    );
                  }

                  final logs = snapshot.data!;

                  return Column(
                    children: logs.map((log) {
                      return PublicLogTile(log: log);
                    }).toList(),
                  );
                },
              ),


            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  builder: (_) => CreateLogBottomSheet(
                    alcohol: alcohol,
                  ),
                );
              },
              child: const Text('Log this drink'),
            ),
          ),
        ),
      ),
    );
  }
}

class _AlcoholHeader extends StatelessWidget {
  final AlcoholModel alcohol;

  const _AlcoholHeader({
    required this.alcohol,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🖼 Alcohol Image
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 1 / 1,
            child: alcohol.imageUrl.isNotEmpty
                ? Image.network(
              alcohol.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return _imagePlaceholder();
              },
            )
                : _imagePlaceholder(),
          ),
        ),

        const SizedBox(height: 16),

        // 🍾 Alcohol Name
        Text(
          alcohol.name,
          style: Theme.of(context).textTheme.headlineSmall,
        ),

        const SizedBox(height: 4),

        // 🏷 Brand
        Text(
          'By ${alcohol.brand}',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: Colors.grey.shade700),
        ),

        const SizedBox(height: 6),

        // 🧪 Type + ABV
        Text(
          '${alcohol.type} • ${alcohol.abv}% ABV',
          style: TextStyle(color: Colors.grey.shade600),
        ),

        if (alcohol.description.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            alcohol.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );

  }
}
class _AlcoholStats extends StatelessWidget {
  final int logCount;
  final double avgRating;

  const _AlcoholStats({
    required this.logCount,
    required this.avgRating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatItem(
            label: 'Logs',
            value: logCount.toString(),
          ),
          _StatItem(
            label: 'Avg rating',
            value: avgRating.toStringAsFixed(1),
            icon: Icons.star,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const _StatItem({
    required this.label,
    required this.value,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (icon != null) ...[
          Row(
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ] else
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

        const SizedBox(height: 4),

        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
Widget _imagePlaceholder() {
  return Container(
    color: Colors.grey.shade200,
    child: const Center(
      child: Icon(
        Icons.local_bar,
        size: 48,
        color: Colors.grey,
      ),
    ),
  );
}


