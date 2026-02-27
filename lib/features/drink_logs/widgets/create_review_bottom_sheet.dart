import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
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
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
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
        isLiked: null,
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
          const SnackBar(
            content: Text('Could not publish review'),
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
              'Review ${widget.alcohol.name}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),
            Text(
              'Your public opinion — visible to everyone.',
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
                    hasRated = true;
                  });
                },
              ),
            ),

            const SizedBox(height: 16),

            // 📝 REVIEW NOTE
            const Text(
              'Your review',
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

            // 🚀 PUBLISH
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: hasRated && !isSaving ? saveReview : null,
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
                        'Publish review',
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

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }
}
