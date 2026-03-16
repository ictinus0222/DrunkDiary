import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/app_theme.dart';
import '../../alcohol/models/alcohol_model.dart';
import '../models/drink_model_dto.dart';

class CreateReviewBottomSheet extends StatefulWidget {
  final AlcoholModel alcohol;

  const CreateReviewBottomSheet({
    super.key,
    required this.alcohol,
  });

  @override
  State<CreateReviewBottomSheet> createState() =>
      _CreateReviewBottomSheetState();
}

class _CreateReviewBottomSheetState extends State<CreateReviewBottomSheet> {
  double rating = 0;
  bool hasRated = false;

  final TextEditingController reviewController = TextEditingController();

  bool isSaving = false;

  File? selectedPhoto;
  bool isUploadingPhoto = false;

  final ImagePicker _picker = ImagePicker();

  // --------------------
  // PHOTO PICKER
  // --------------------
  Future<void> pickPhoto(BuildContext context) async {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    showModalBottomSheet(
      context: context,
      backgroundColor: customColors.deepCardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.onSurface),
              title: Text('Take a photo', style: Theme.of(context).textTheme.bodyLarge),
              onTap: () async {
                Navigator.pop(context);
                final picked = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                  maxWidth: 1080,
                  maxHeight: 1350,
                );
                if (picked != null) {
                  setState(() => selectedPhoto = File(picked.path));
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Theme.of(context).colorScheme.onSurface),
              title: Text('Choose from gallery', style: Theme.of(context).textTheme.bodyLarge),
              onTap: () async {
                Navigator.pop(context);
                final picked = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                  maxWidth: 1080,
                  maxHeight: 1350,
                );
                if (picked != null) {
                  setState(() => selectedPhoto = File(picked.path));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // --------------------
  // SAVE REVIEW
  // --------------------
  Future<void> saveReview() async {
    if (!hasRated || isSaving) return;

    final user = FirebaseAuth.instance.currentUser!;
    setState(() => isSaving = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      // 🔒 DETERMINISTIC REVIEW ID
      final reviewDocId = '${user.uid}_${widget.alcohol.id}';

      final review = DrinkLogModel(
        id: reviewDocId,
        userId: user.uid,
        alcoholId: widget.alcohol.id,
        username: userDoc['username'] ?? 'Unknown',
        userPhotoUrl: userDoc['photoUrl'],
        alcoholName: widget.alcohol.name,
        alcoholType: widget.alcohol.type,
        rating: rating,
        note: reviewController.text.trim(),
        logKind: LogKind.review,
        createdAt: DateTime.now(),
      );

      final ref =
          FirebaseFirestore.instance.collection('drink_logs').doc(reviewDocId);

      // ✅ CREATE OR OVERWRITE (idempotent)
      await ref.set(
        review.toMap(),
        SetOptions(merge: true),
      );

      if (selectedPhoto != null) {
        await _uploadPhoto(ref, user.uid);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not publish review', style: TextStyle(color: Theme.of(context).colorScheme.onError)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> _uploadPhoto(
    DocumentReference ref,
    String userId,
  ) async {
    try {
      setState(() => isUploadingPhoto = true);

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('drink_reviews')
          .child(userId)
          .child('${ref.id}.jpg');

      await storageRef.putFile(selectedPhoto!);
      final url = await storageRef.getDownloadURL();

      await ref.update({
        'photoUrl': url,
        'photoUploadedAt': FieldValue.serverTimestamp(),
      });
    } finally {
      if (mounted) setState(() => isUploadingPhoto = false);
    }
  }

  // --------------------
  // UI
  // --------------------
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
              'Review ${widget.alcohol.name}',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),
            Text(
              'Rate and record for your diary.',
              style: textTheme.bodyMedium?.copyWith(color: customColors.textMuted),
            ),

            const SizedBox(height: 24),

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
                    hasRated = true;
                  });
                },
              ),
            ),

            const SizedBox(height: 16),

            // 📝 REVIEW NOTE
            Text(
              'Your review',
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

            const SizedBox(height: 32),

            // 🚀 PUBLISH
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: hasRated && !isSaving ? saveReview : null,
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
                        'Save review',
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

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }
}
