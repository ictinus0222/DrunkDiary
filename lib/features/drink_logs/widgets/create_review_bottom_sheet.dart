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

class _CreateReviewBottomSheetState
    extends State<CreateReviewBottomSheet> {
  double rating = 0;
  bool hasRated = false;

  final TextEditingController reviewController =
  TextEditingController();

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
                  setState(() =>
                  selectedPhoto = File(picked.path));
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
                  setState(() =>
                  selectedPhoto = File(picked.path));
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

      final review = DrinkLogModel(
        id: '',
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

      final ref = await FirebaseFirestore.instance
          .collection('drink_logs')
          .add(review.toMap());

      if (selectedPhoto != null) {
        await _uploadPhoto(ref, user.uid);
      }

      if (mounted) Navigator.pop(context);
    } catch (_) {
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review ${widget.alcohol.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 6),
            const Text(
              'Your public opinion — visible to everyone.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),

            const SizedBox(height: 16),

            // ⭐ RATING
            const Text(
              'Your rating',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('${rating.toStringAsFixed(1)} / 5'),
            Slider(
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

            const SizedBox(height: 16),

            // REVIEW TEXT
            const Text(
              'Your review',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reviewController,
              maxLines: 4,
              textCapitalization:
              TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText:
                'What did you like or dislike about it?',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // // PHOTO
            // const Text(
            //   'Add a photo (optional)',
            //   style: TextStyle(fontWeight: FontWeight.w600),
            // ),
            // const SizedBox(height: 8),
            // GestureDetector(
            //   onTap: () => pickPhoto(context),
            //   child: Container(
            //     height: 120,
            //     width: double.infinity,
            //     decoration: BoxDecoration(
            //       color: Colors.grey.shade900,
            //       borderRadius: BorderRadius.circular(12),
            //       border:
            //       Border.all(color: Colors.grey.shade700),
            //     ),
            //     child: selectedPhoto == null
            //         ? const Center(
            //       child: Icon(
            //         Icons.camera_alt_outlined,
            //       ),
            //     )
            //         : ClipRRect(
            //       borderRadius:
            //       BorderRadius.circular(12),
            //       child: Image.file(
            //         selectedPhoto!,
            //         fit: BoxFit.cover,
            //       ),
            //     ),
            //   ),
            // ),
            //
            // const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: hasRated && !isSaving
                    ? saveReview
                    : null,
                child: isSaving
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child:
                  CircularProgressIndicator(
                      strokeWidth: 2),
                )
                    : const Text('Publish review'),
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
