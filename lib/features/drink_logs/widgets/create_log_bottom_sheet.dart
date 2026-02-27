import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../alcohol/models/alcohol_model.dart';
import '../models/drink_model_dto.dart';

class CreateLogBottomSheet extends StatefulWidget {
  final AlcoholModel alcohol;
  const CreateLogBottomSheet({super.key, required this.alcohol});

  @override
  State<CreateLogBottomSheet> createState() => _CreateLogBottomSheetState();
}

class _CreateLogBottomSheetState extends State<CreateLogBottomSheet> {
  bool? liked; // 👍 true | 👎 false | null
  bool showNoteField = false;

  final TextEditingController noteController = TextEditingController();

  bool isSaving = false;
  bool isUploadingPhoto = false;

  File? selectedPhoto;
  final ImagePicker _picker = ImagePicker();

  // =====================
  // PHOTO PICKER
  // =====================
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

  // =====================
  // SAVE LOG
  // =====================
  Future<void> saveLog() async {
    if (isSaving) return;

    final user = FirebaseAuth.instance.currentUser!;
    setState(() => isSaving = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final log = DrinkLogModel(
        id: '',
        userId: user.uid,
        alcoholId: widget.alcohol.id,
        username: userDoc['username'] ?? 'Unknown',
        userPhotoUrl: userDoc['photoUrl'],
        alcoholName: widget.alcohol.name,
        alcoholType: widget.alcohol.type,
        rating: null,
        isLiked: liked,
        note: noteController.text.isNotEmpty ? noteController.text : null,
        logKind: LogKind.log,
        createdAt: DateTime.now(),
      );

      final logRef = await FirebaseFirestore.instance
          .collection('drink_logs')
          .add(log.toMap());

      if (selectedPhoto != null) {
        await _uploadPhoto(logRef, user.uid);
      }

      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save log'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> _uploadPhoto(
    DocumentReference logRef,
    String userId,
  ) async {
    try {
      setState(() => isUploadingPhoto = true);

      final ref = FirebaseStorage.instance
          .ref()
          .child('drink_logs')
          .child(userId)
          .child('${logRef.id}.jpg');

      await ref.putFile(selectedPhoto!);

      final url = await ref.getDownloadURL();

      await logRef.update({
        'photoUrl': url,
        'photoUploadedAt': FieldValue.serverTimestamp(),
      });
    } finally {
      if (mounted) {
        setState(() => isUploadingPhoto = false);
      }
    }
  }

  // =====================
  // UI
  // =====================
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
              'Log ${widget.alcohol.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 6),
            const Text(
              'A quick moment — only you can see this.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),

            const SizedBox(height: 16),

            // 👍 / 👎
            const Text(
              'Your take',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(
                      Icons.thumb_up,
                      color: liked == true ? Colors.green : null,
                    ),
                    label: const Text('Like'),
                    onPressed: () => setState(() => liked = true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(
                      Icons.thumb_down,
                      color: liked == false ? Colors.red : null,
                    ),
                    label: const Text('Dislike'),
                    onPressed: () => setState(() => liked = false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // NOTE
            TextButton.icon(
              icon: const Icon(Icons.edit_note),
              label: const Text('Add a note'),
              onPressed: () => setState(() => showNoteField = !showNoteField),
            ),

            if (showNoteField) ...[
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'What made this moment memorable?',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // PHOTO
            const Text(
              'Add a photo',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => pickPhoto(context),
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade700),
                ),
                child: selectedPhoto == null
                    ? const Center(
                        child: Icon(Icons.camera_alt_outlined),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          selectedPhoto!,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : saveLog,
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save log'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
