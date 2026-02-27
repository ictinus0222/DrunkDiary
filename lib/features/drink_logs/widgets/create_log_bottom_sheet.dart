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
            Text(
              'Log ${widget.alcohol.name}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),
            Text(
              'A quick moment — only you can see this.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),

            const SizedBox(height: 24),

            // 👍 / 👎
            const Text(
              'Your take',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(
                      Icons.thumb_up_alt_outlined,
                      color:
                          liked == true ? Colors.green : Colors.grey.shade400,
                      size: 20,
                    ),
                    label: Text(
                      'Like',
                      style: TextStyle(
                        color:
                            liked == true ? Colors.green : Colors.grey.shade400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color:
                            liked == true ? Colors.green : Colors.grey.shade800,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: liked == true
                          ? Colors.green.withOpacity(0.1)
                          : Colors.transparent,
                    ),
                    onPressed: () => setState(() => liked = true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(
                      Icons.thumb_down_alt_outlined,
                      color: liked == false ? Colors.red : Colors.grey.shade400,
                      size: 20,
                    ),
                    label: Text(
                      'Dislike',
                      style: TextStyle(
                        color:
                            liked == false ? Colors.red : Colors.grey.shade400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color:
                            liked == false ? Colors.red : Colors.grey.shade800,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: liked == false
                          ? Colors.red.withOpacity(0.1)
                          : Colors.transparent,
                    ),
                    onPressed: () => setState(() => liked = false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // NOTE
            InkWell(
              onTap: () => setState(() => showNoteField = !showNoteField),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      showNoteField ? Icons.close : Icons.edit_note,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      showNoteField ? 'Remove note' : 'Add a note',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (showNoteField) ...[
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'What made this moment memorable?',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade800),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Colors.amber, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade800),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // PHOTO
            const Text(
              'Add a photo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => pickPhoto(context),
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade800),
                  image: selectedPhoto != null
                      ? DecorationImage(
                          image: FileImage(selectedPhoto!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: selectedPhoto == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined,
                              size: 32, color: Colors.grey.shade500),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to upload',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 13),
                          ),
                        ],
                      )
                    : null,
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : saveLog,
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
                        'Save log',
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
