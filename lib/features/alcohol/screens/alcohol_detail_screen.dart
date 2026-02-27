import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../drink_logs/repositories/drink_log_repository.dart';
import '../../drink_logs/widgets/create_review_bottom_sheet.dart';
import '../../drink_logs/widgets/edit_review_screen.dart';
import '../models/alcohol_model.dart';
import '../../drink_logs/models/drink_model_dto.dart';
import '../../drink_logs/widgets/create_log_bottom_sheet.dart';
import '../../drink_logs/widgets/drink_log_card.dart';
import '../widgets/public_log_tile.dart';

class AlcoholDetailScreen extends StatelessWidget {
  final DrinkLogRepository _drinkLogRepository = DrinkLogRepository();

  final AlcoholModel alcohol;

  AlcoholDetailScreen({
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
        .map((snapshot) =>
            snapshot.docs.map(DrinkLogModel.fromFirestore).toList());
  }

  Future<(int, double)> _fetchGlobalStats() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('drink_logs')
        .where('alcoholId', isEqualTo: alcohol.id)
        .where('visibility', isEqualTo: 'public')
        .get();

    final docs = snapshot.docs;
    if (docs.isEmpty) return (0, 0.0);

    final ratings =
        docs.map((doc) => (doc['rating'] as num).toDouble()).toList();
    final avgRating = ratings.reduce((a, b) => a + b) / ratings.length;

    return (docs.length, avgRating);
  }

  Future<void> onWriteReviewPressed(BuildContext context) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final alcoholId = alcohol.id;

    final query = await FirebaseFirestore.instance
        .collection('drink_logs')
        .where('userId', isEqualTo: userId)
        .where('alcoholId', isEqualTo: alcoholId)
        .where('logKind', isEqualTo: 'review')
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final review = DrinkLogModel.fromFirestore(query.docs.first);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReviewEditorScreen(
            alcohol: alcohol,
            existingReview: review,
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => CreateReviewBottomSheet(
          alcohol: alcohol,
        ),
      );
    }
  }

  Future<bool> _hasUserReviewed() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final query = await FirebaseFirestore.instance
        .collection('drink_logs')
        .where('userId', isEqualTo: userId)
        .where('alcoholId', isEqualTo: alcohol.id)
        .where('logKind', isEqualTo: 'review')
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 4.0, bottom: 4.0),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.15),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 4.0, bottom: 4.0),
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.15),
              child: IconButton(
                icon: const Icon(Icons.share, color: Colors.white, size: 20),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<DrinkLogModel>>(
        stream: _logsStream(),
        builder: (context, snapshot) {
          final logs = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.only(
                bottom: 120), // Padding for the fixed bottom bar
            children: [
              _HeroImage(alcohol: alcohol),
              const SizedBox(height: 24),
              _ProductInfo(alcohol: alcohol),
              FutureBuilder<(int, double)>(
                future: _fetchGlobalStats(),
                builder: (context, statsSnapshot) {
                  final (logCount, avgRating) = statsSnapshot.data ?? (0, 0.0);
                  return _WineStats(logCount: logCount, avgRating: avgRating);
                },
              ),
              _AboutSection(alcohol: alcohol),
              if (logs.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Your logs',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                ...logs.map((log) => DrinkLogCard(log: log)),
              ],
              const SizedBox(height: 32),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Community',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<DrinkLogModel>>(
                future: _drinkLogRepository.fetchReviewsForAlcohol(alcohol.id),
                builder: (context, communitySnapshot) {
                  if (communitySnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                          child:
                              CircularProgressIndicator(color: Colors.amber)),
                    );
                  }
                  final reviews = communitySnapshot.data ?? [];
                  if (reviews.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No reviews yet. Be the first to review this drink.',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    );
                  }
                  return Column(
                    children: reviews
                        .map((review) => PublicLogTile(log: review))
                        .toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
      // Overlay bottom bar using a bottom sheet / bottom nav bar pattern
      bottomSheet: _BottomActionBar(
        alcohol: alcohol,
        onWriteReviewPressed: () => onWriteReviewPressed(context),
        hasUserReviewedFuture: _hasUserReviewed(),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  final AlcoholModel alcohol;

  const _HeroImage({required this.alcohol});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: AspectRatio(
          aspectRatio: 1,
          child: alcohol.imageUrl.isNotEmpty
              ? Image.network(
                  alcohol.imageUrl,
                  fit: BoxFit.contain, // best for bottles to ensure no crop
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                        child: CircularProgressIndicator(color: Colors.amber));
                  },
                  errorBuilder: (_, __, ___) => _imagePlaceholder(),
                )
              : _imagePlaceholder(),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: Colors.white,
      child: const Center(
        child: Icon(Icons.local_bar, size: 48, color: Colors.grey),
      ),
    );
  }
}

class _ProductInfo extends StatelessWidget {
  final AlcoholModel alcohol;

  const _ProductInfo({required this.alcohol});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            alcohol.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'By ${alcohol.brand}',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip(alcohol.type),
              if (alcohol.origin.isNotEmpty) _buildChip(alcohol.origin),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ABV',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500)),
              Text('${alcohol.abv.toStringAsFixed(1)}%',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: alcohol.abv / 100,
              minHeight: 12,
              backgroundColor: Colors.grey.shade800,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade900.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style:
            const TextStyle(color: Colors.amber, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _WineStats extends StatelessWidget {
  final int logCount;
  final double avgRating;

  const _WineStats({required this.logCount, required this.avgRating});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('User reviews',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              Row(
                children: [
                  ...List.generate(5, (index) {
                    return Icon(
                      index < avgRating.round()
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    );
                  }),
                  const SizedBox(width: 8),
                  Text('${avgRating.toStringAsFixed(1)}/5',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatCol(label: 'Total Logs', value: logCount.toString()),
                Container(height: 32, width: 1, color: Colors.grey.shade700),
                _StatCol(
                    label: 'Avg Rating',
                    value: avgRating.toStringAsFixed(1),
                    icon: Icons.star),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const _StatCol({required this.label, required this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.amber, size: 18),
            const SizedBox(width: 4)
          ],
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
      ],
    );
  }
}

class _AboutSection extends StatelessWidget {
  final AlcoholModel alcohol;

  const _AboutSection({required this.alcohol});

  @override
  Widget build(BuildContext context) {
    if (alcohol.description.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('About',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            alcohol.description,
            style: TextStyle(
                color: Colors.grey.shade400, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final AlcoholModel alcohol;
  final VoidCallback onWriteReviewPressed;
  final Future<bool> hasUserReviewedFuture;

  const _BottomActionBar({
    required this.alcohol,
    required this.onWriteReviewPressed,
    required this.hasUserReviewedFuture,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      decoration: BoxDecoration(
        color: Colors.black, // Dark overlay matching background
        border: Border(top: BorderSide(color: Colors.grey.shade900)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: FutureBuilder<bool>(
              future: hasUserReviewedFuture,
              builder: (context, snapshot) {
                final hasReviewed = snapshot.data ?? false;
                return OutlinedButton.icon(
                  onPressed: onWriteReviewPressed,
                  icon: const Icon(Icons.edit, color: Colors.amber, size: 20),
                  label: Text(
                    hasReviewed ? 'Edit Review' : 'Review',
                    style: const TextStyle(
                        color: Colors.amber, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.amber, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => CreateLogBottomSheet(alcohol: alcohol),
                );
              },
              icon: const Icon(Icons.add, color: Colors.black, size: 20),
              label: const Text(
                'Log This Drink',
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
