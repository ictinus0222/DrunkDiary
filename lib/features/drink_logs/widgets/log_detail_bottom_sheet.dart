import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../app/app_theme.dart';
import '../../../core/constants/reaction_config.dart';
import '../models/drink_model_dto.dart';
import '../../alcohol/models/alcohol_model.dart';
import '../../drink_logs/widgets/edit_review_bottom_sheet.dart';
import '../../../core/widgets/app_shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LogDetailBottomSheet extends StatefulWidget {
  final DrinkLogModel log;

  const LogDetailBottomSheet({
    super.key,
    required this.log,
  });

  @override
  State<LogDetailBottomSheet> createState() => _LogDetailBottomSheetState();
}

class _LogDetailBottomSheetState extends State<LogDetailBottomSheet> {
  bool isDeleting = false;
  late DrinkLogModel _log;
  AlcoholModel? _alcohol;
  bool _isLoadingAlcohol = true;

  @override
  void initState() {
    super.initState();
    _log = widget.log;
    _fetchAlcohol();
  }

  Future<void> _fetchAlcohol() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('alcohols')
          .doc(_log.alcoholId)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _alcohol = AlcoholModel.fromFirestore(doc);
          _isLoadingAlcohol = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingAlcohol = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingAlcohol = false);
    }
  }

  Future<void> _deleteLog() async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: const Text('This action can’t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: colorScheme.onSurface)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isDeleting = true);

    try {
      await FirebaseFirestore.instance
          .collection('drink_logs')
          .doc(_log.id)
          .delete();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete log: $e', style: TextStyle(color: Theme.of(context).colorScheme.onError)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final bool isReview = _log.logKind == LogKind.review;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: customColors.deepCardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Stack(
        children: [
          // Subtle radial glow background behind the image area
          Positioned(
            top: -50,
            left: MediaQuery.of(context).size.width / 2 - 150,
            child: Container(
              height: 300,
              width: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.18),
                    Colors.transparent,
                  ],
                  radius: 0.6,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Bar (Close Button)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Close button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close,
                              size: 18, color: colorScheme.onSurface.withOpacity(0.7)),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content area
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottomInset),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Photo Area
                        if (_log.photoUrl != null && _log.photoUrl!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Hero(
                                  tag: 'alcohol_${_log.id}_photo',
                                  child: CachedNetworkImage(
                                    imageUrl: _log.photoUrl!,
                                    height: 240,
                                    width: 160,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const AppShimmer(),
                                    errorWidget: (context, url, error) => const Icon(Icons.error),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Title
                        Text(
                          _log.alcoholName,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Rating or Liked status
                        if (isReview)
                          Row(
                            children: [
                              ...List.generate(
                                  5,
                                  (index) => Icon(
                                        index < (_log.rating?.round() ?? 0)
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: colorScheme.primary,
                                        size: 22,
                                      )),
                              const SizedBox(width: 10),
                              Text(
                                '${(_log.rating ?? 0.0).toStringAsFixed(1)} / 5',
                                style: textTheme.titleMedium,
                              ),
                            ],
                          )
                        else if (!isReview && _log.reaction != null)
                          Row(
                            children: [
                              Icon(
                                ReactionConfig.getIcon(_log.reaction!),
                                color: ReactionConfig.getColor(_log.reaction!),
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                ReactionConfig.getLabel(_log.reaction!),
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 24),

                        // Stats Grid
                        Row(
                          children: [
                            Expanded(
                                child: _buildGridCard(
                                    context,
                                    Icons.wine_bar,
                                    'Category',
                                    _log.alcoholType,
                                    colorScheme.primary)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _buildGridCard(
                                    context,
                                    Icons.local_fire_department,
                                    'ABV',
                                    _isLoadingAlcohol
                                        ? '...'
                                        : (_alcohol?.abv != null
                                            ? '${_alcohol!.abv}%'
                                            : '--'),
                                    colorScheme.primary)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                                child: _buildGridCard(
                                    context,
                                    Icons.calendar_today_outlined,
                                    'Date',
                                    DateFormat('MMMM d, yyyy')
                                        .format(_log.createdAt),
                                    colorScheme.primary)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _buildGridCard(
                                    context,
                                    Icons.access_time,
                                    'Time',
                                    DateFormat('h:mm a').format(_log.createdAt),
                                    colorScheme.primary)),
                          ],
                        ),

                        // Notes
                        if (_log.note != null && _log.note!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: customColors.cardBackground,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'NOTES',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: customColors.textMuted,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _log.note!,
                                  style: textTheme.bodyMedium?.copyWith(
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Edit Button (if review)
                        if (isReview && _alcohol != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    useSafeArea: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => EditReviewBottomSheet(
                                      alcohol: _alcohol!,
                                      existingReview: _log,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.edit, size: 20),
                                label: Text('Edit Review',
                                    style: textTheme.titleMedium?.copyWith(
                                        color: colorScheme.onPrimary,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),

                        // Delete Button
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: colorScheme.error,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              backgroundColor: colorScheme.error.withOpacity(0.05),
                            ),
                            onPressed: isDeleting ? null : _deleteLog,
                            child: isDeleting
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: colorScheme.error, strokeWidth: 2))
                                : Text('Delete Entry',
                                    style: textTheme.titleMedium?.copyWith(
                                        color: colorScheme.error,
                                        fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard(
      BuildContext context, IconData icon, String title, String value, Color iconColor) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: customColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: textTheme.bodySmall?.copyWith(color: customColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
