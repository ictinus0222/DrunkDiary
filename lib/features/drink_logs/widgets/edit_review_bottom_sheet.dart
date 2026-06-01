import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../alcohol/models/alcohol_model.dart';
import '../models/drink_model_dto.dart';

class EditReviewBottomSheet extends StatefulWidget {
  final DrinkLogModel existingReview;
  final AlcoholModel alcohol;

  const EditReviewBottomSheet({
    super.key,
    required this.existingReview,
    required this.alcohol,
  });

  @override
  State<EditReviewBottomSheet> createState() => _EditReviewBottomSheetState();
}

class _EditReviewBottomSheetState extends State<EditReviewBottomSheet> {
  late double rating;
  late TextEditingController reviewController;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    rating = widget.existingReview.rating ?? 0.0;
    reviewController =
        TextEditingController(text: widget.existingReview.note ?? '');
  }

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }

  Future<void> saveReview() async {
    if (isSaving) return;

    setState(() => isSaving = true);

    try {
      final reviewDocId = widget.existingReview.id;

      final data = {
        'rating': rating,
        'note': reviewController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('drink_logs')
          .doc(reviewDocId)
          .update(data);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update review', style: TextStyle(color: Theme.of(context).colorScheme.onError)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: customColors.deepCardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle pill
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: customColors.borderDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // TITLE
            Text(
              'Edit review for ${widget.alcohol.name}',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),
            Text(
              'Update your rating and thoughts.',
              style: textTheme.bodyMedium?.copyWith(color: customColors.textMuted),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ⭐ RATING
            Text(
              'Your rating',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${rating.toStringAsFixed(1)} / 5',
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: colorScheme.primary,
                inactiveTrackColor: customColors.borderDark,
                thumbColor: colorScheme.primary,
                overlayColor: colorScheme.primary.withOpacity(0.2),
              ),
              child: Slider(
                value: rating,
                min: 0,
                max: 5,
                divisions: 10,
                onChanged: (value) {
                  setState(() {
                    rating = value;
                  });
                },
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // 📝 REVIEW NOTE
            Text(
              'Your thoughts',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reviewController,
              maxLines: 4,
              style: textTheme.bodyMedium,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'What did you like or dislike about it?',
                hintStyle: textTheme.bodyMedium?.copyWith(color: customColors.textMuted),
                filled: true,
                fillColor: customColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: customColors.borderDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: customColors.borderDark),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // 🚀 UPDATE
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : saveReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: colorScheme.primary.withOpacity(0.5),
                ),
                child: isSaving
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: colorScheme.onPrimary),
                      )
                    : Text(
                        'Update review',
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
