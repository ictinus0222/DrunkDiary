import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/flags/feature_flags.dart';
import '../../wishlist/widgets/wishlist_action_button.dart';
import '../../drink_logs/widgets/create_review_bottom_sheet.dart';
import '../../drink_logs/widgets/edit_review_bottom_sheet.dart';
import '../models/alcohol_model.dart';
import '../../drink_logs/models/drink_model_dto.dart';
import '../../drink_logs/widgets/create_log_bottom_sheet.dart';
import '../../drink_logs/widgets/drink_log_card.dart';

class AlcoholDetailScreen extends StatelessWidget {
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

  Stream<(int, double, int, int)> _advancedStatsStream() {
    final user = FirebaseAuth.instance.currentUser!;
    return FirebaseFirestore.instance
        .collection('drink_logs')
        .where('alcoholId', isEqualTo: alcohol.id)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs.map(DrinkLogModel.fromFirestore).toList();
      if (items.isEmpty) return (0, 0.0, 0, 0);

      final ratingDocs =
          items.where((d) => d.logKind == LogKind.review).toList();
      double avgRating = 0.0;
      if (ratingDocs.isNotEmpty) {
        final ratings = ratingDocs.map((doc) => doc.rating ?? 0.0).toList();
        avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
      }

      final personalLogs = items
          .where((d) => d.userId == user.uid && d.logKind == LogKind.log)
          .toList();

      int likes = 0;
      int dislikes = 0;
      final generalLogs = items.where((d) => d.logKind == LogKind.log).toList();
      for (var log in generalLogs) {
        final bool? isLiked =
            log.isLiked ?? (log.rating != null ? log.rating! >= 1.0 : null);

        if (isLiked == true) {
          likes++;
        } else if (isLiked == false) {
          dislikes++;
        }
      }

      int likeRatio = 0;
      if (likes + dislikes > 0) {
        likeRatio = (likes * 100 / (likes + dislikes)).round();
      }

      return (generalLogs.length, avgRating, personalLogs.length, likeRatio);
    });
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
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => EditReviewBottomSheet(
          alcohol: alcohol,
          existingReview: review,
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
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
          WishlistActionButton(alcohol: alcohol),
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
              StreamBuilder<(int, double, int, int)>(
                stream: _advancedStatsStream(),
                builder: (context, statsSnapshot) {
                  final (totalLogs, avgRating, personalLogs, likeRatio) =
                      statsSnapshot.data ?? (0, 0.0, 0, 0);
                  return _WineStats(
                      totalLogs: totalLogs,
                      personalLogs: personalLogs,
                      avgRating: avgRating,
                      likeRatio: likeRatio);
                },
              ),
              Consumer(
                builder: (context, ref, child) {
                  final flagsAsync = ref.watch(featureFlagsProvider);
                  return flagsAsync.when(
                    data: (flags) => flags.personalMeaningEnabled
                        ? _PersonalMeaningSection(alcohol: alcohol)
                        : _AboutSection(alcohol: alcohol),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => _AboutSection(alcohol: alcohol),
                  );
                },
              ),
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
  final int totalLogs;
  final int personalLogs;
  final double avgRating;
  final int likeRatio;

  const _WineStats({
    required this.totalLogs,
    required this.personalLogs,
    required this.avgRating,
    required this.likeRatio,
  });

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
              const Text('Community Stats',
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
                _StatCol(label: 'Total Logs', value: totalLogs.toString()),
                Container(height: 32, width: 1, color: Colors.grey.shade700),
                _StatCol(label: 'Your Logs', value: personalLogs.toString()),
                Container(height: 32, width: 1, color: Colors.grey.shade700),
                _StatCol(
                    label: 'Like Ratio',
                    value: '$likeRatio%',
                    icon: Icons.thumb_up_alt_outlined),
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

class _PersonalMeaningSection extends StatefulWidget {
  final AlcoholModel alcohol;
  const _PersonalMeaningSection({required this.alcohol});

  @override
  State<_PersonalMeaningSection> createState() =>
      _PersonalMeaningSectionState();
}

class _PersonalMeaningSectionState extends State<_PersonalMeaningSection> {
  final TextEditingController _controller = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('user_alcohol_meta')
          .doc('${user.uid}_${widget.alcohol.id}')
          .set({
        'personalNote': _controller.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      setState(() => _isEditing = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save note')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_alcohol_meta')
          .doc('${user.uid}_${widget.alcohol.id}')
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final note = data?['personalNote'] as String? ?? '';

        if (!_isEditing && !_controller.text.isNotEmpty && note.isNotEmpty) {
          _controller.text = note;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'What this means to you',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!_isEditing)
                    IconButton(
                      icon: Icon(note.isEmpty ? Icons.add : Icons.edit,
                          color: Colors.amber, size: 20),
                      onPressed: () => setState(() => _isEditing = true),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (_isEditing)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      maxLines: null,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Define what this bottle is for you...',
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        filled: true,
                        fillColor: Colors.grey.shade900,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isSaving
                              ? null
                              : () => setState(() => _isEditing = false),
                          child: const Text('Cancel',
                              style: TextStyle(color: Colors.grey)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _saveNote,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.black),
                                )
                              : const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                )
              else if (note.isNotEmpty)
                Text(
                  note,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                GestureDetector(
                  onTap: () => setState(() => _isEditing = true),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade800),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Define what this bottle means to you...',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
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

// Extension to DashBorder support for the placeholder
class DashStyle {
  final double length;
  final double gap;
  const DashStyle(this.length, this.gap);
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
