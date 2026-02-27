import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
          const SnackBar(content: Text('Could not update review')),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141414), // Dark background matching theme
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // TITLE
            Text(
              'Edit review for ${widget.alcohol.name}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),
            Text(
              'Update your rating and thoughts.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),

            const SizedBox(height: 24),

            // ⭐ RATING
            const Text(
              'Your rating',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${rating.toStringAsFixed(1)} / 5',
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.amber,
                inactiveTrackColor: Colors.grey.shade800,
                thumbColor: Colors.amber,
                overlayColor: Colors.amber.withOpacity(0.2),
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

            const SizedBox(height: 16),

            // 📝 REVIEW NOTE
            const Text(
              'Your thoughts',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reviewController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'What did you like or dislike about it?',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade800),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.amber, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade800),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 🚀 UPDATE
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : saveReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.amber.withOpacity(0.5),
                ),
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                      )
                    : const Text(
                        'Update review',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
