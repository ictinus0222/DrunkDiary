import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 4.0, bottom: 4.0),
          child: CircleAvatar(
            backgroundColor: colorScheme.onSurface.withOpacity(0.15),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: colorScheme.onSurface, size: 20),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Your logs',
                    style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.onSurface, // typically white for product background
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
                    return Center(
                        child: CircularProgressIndicator(color: colorScheme.primary));
                  },
                  errorBuilder: (_, __, ___) => _imagePlaceholder(context),
                )
              : _imagePlaceholder(context),
        ),
      ),
    );
  }

  Widget _imagePlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.onSurface,
      child: Center(
        child: Icon(Icons.local_bar, size: 48, color: Theme.of(context).extension<AppCustomColors>()!.textMuted),
      ),
    );
  }
}

class _ProductInfo extends StatelessWidget {
  final AlcoholModel alcohol;

  const _ProductInfo({required this.alcohol});

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            alcohol.name,
            style: textTheme.headlineMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'By ${alcohol.brand}',
            style: textTheme.titleMedium?.copyWith(
              color: customColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip(context, alcohol.type),
              if (alcohol.origin.isNotEmpty) _buildChip(context, alcohol.origin),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ABV',
                  style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500)),
              Text('${alcohol.abv.toStringAsFixed(1)}%',
                  style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: alcohol.abv / 100,
              minHeight: 12,
              backgroundColor: customColors.deepCardBackground,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600),
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
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Community Stats',
                  style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold)),
              Row(
                children: [
                  ...List.generate(5, (index) {
                    return Icon(
                      index < avgRating.round()
                          ? Icons.star
                          : Icons.star_border,
                      color: colorScheme.primary,
                      size: 20,
                    );
                  }),
                  const SizedBox(width: 8),
                  Text('${avgRating.toStringAsFixed(1)}/5',
                      style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: customColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatCol(label: 'Total Logs', value: totalLogs.toString()),
                Container(height: 32, width: 1, color: customColors.borderLight),
                _StatCol(label: 'Your Logs', value: personalLogs.toString()),
                Container(height: 32, width: 1, color: customColors.borderLight),
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
    final colorScheme = Theme.of(context).colorScheme;
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, color: colorScheme.primary, size: 18),
            const SizedBox(width: 4)
          ],
          Text(value,
              style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 4),
        Text(label,
            style: textTheme.bodySmall?.copyWith(color: customColors.textMuted)),
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
        SnackBar(content: Text('Failed to save note', style: TextStyle(color: Theme.of(context).colorScheme.onError)), backgroundColor: Theme.of(context).colorScheme.error),
      );
    } finally {
      if(mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                  Text(
                    'What this means to you',
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!_isEditing)
                    IconButton(
                      icon: Icon(note.isEmpty ? Icons.add : Icons.edit,
                          color: colorScheme.primary, size: 20),
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
                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Define what this bottle is for you...',
                        hintStyle: textTheme.bodyMedium?.copyWith(color: customColors.textMuted),
                        filled: true,
                        fillColor: customColors.cardBackground,
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
                          child: Text('Cancel',
                              style: TextStyle(color: customColors.textMuted)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _saveNote,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isSaving
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: colorScheme.onPrimary),
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
                  style: textTheme.bodyMedium?.copyWith(
                    color: customColors.textMuted,
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
                      border: Border.all(color: customColors.borderLight),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Define what this bottle means to you...',
                      style:
                          textTheme.bodyMedium?.copyWith(color: customColors.textMuted),
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
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (alcohol.description.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About',
              style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            alcohol.description,
            style: textTheme.bodyMedium?.copyWith(
                color: customColors.textMuted, height: 1.5),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

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
    final colorScheme = Theme.of(context).colorScheme;
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: customColors.borderDark)),
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
                  icon: Icon(Icons.edit, color: colorScheme.primary, size: 20),
                  label: Text(
                    hasReviewed ? 'Edit Review' : 'Review',
                    style: TextStyle(
                        color: colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: colorScheme.primary, width: 1.5),
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
              icon: Icon(Icons.add, color: colorScheme.onPrimary, size: 20),
              label: Text(
                'Log This Drink',
                style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
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
