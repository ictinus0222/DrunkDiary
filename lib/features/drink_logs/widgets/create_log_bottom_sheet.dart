import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/app_theme.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/constants/reaction_config.dart';
import '../../alcohol/models/alcohol_model.dart';
import '../models/drink_model_dto.dart';

class CreateLogBottomSheet extends StatefulWidget {
  final AlcoholModel alcohol;
  const CreateLogBottomSheet({super.key, required this.alcohol});

  @override
  State<CreateLogBottomSheet> createState() => _CreateLogBottomSheetState();
}

class _CreateLogBottomSheetState extends State<CreateLogBottomSheet> {
  DrinkReaction? selectedReaction;
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
        reaction: selectedReaction,
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

      // 🏆 Log analytics event
      await AnalyticsService().logCreateDrinkLog(
        logKind: 'log',
        alcoholType: widget.alcohol.type,
        reaction: selectedReaction?.name ?? 'unknown',
      );

      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save log', style: TextStyle(color: Theme.of(context).colorScheme.onError)),
            backgroundColor: Theme.of(context).colorScheme.error,
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
            Text(
              'Log ${widget.alcohol.name}',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),
            Text(
              'A quick moment — only you can see this.',
              style: textTheme.bodyMedium?.copyWith(
                color: customColors.textMuted,
              ),
            ),

            const SizedBox(height: 24),

            // 👍 / 👎
            Text(
              'Your take',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: DrinkReaction.values.map((reaction) {
                final isSelected = selectedReaction == reaction;
                final label = ReactionConfig.getLabel(reaction);
                final icon = ReactionConfig.getIcon(reaction);
                final color = ReactionConfig.getColor(reaction);

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: reaction == DrinkReaction.values.last ? 0 : 8,
                    ),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: isSelected ? color : customColors.borderDark,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: isSelected
                            ? color.withOpacity(0.12)
                            : Colors.transparent,
                      ),
                      onPressed: () => setState(() => selectedReaction = reaction),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            color: isSelected ? color : customColors.textMuted,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            textAlign: TextAlign.center,
                            style: textTheme.labelSmall?.copyWith(
                              color: isSelected ? color : customColors.textMuted,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
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
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      showNoteField ? 'Remove note' : 'Add a note',
                      style: textTheme.titleSmall?.copyWith(
                        color: colorScheme.primary,
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
                style: textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'What made this moment memorable?',
                  hintStyle: textTheme.bodyMedium?.copyWith(color: customColors.textMuted),
                  filled: true,
                  fillColor: customColors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: customColors.borderDark),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: colorScheme.primary, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: customColors.borderDark),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // PHOTO
            Text(
              'Add a photo',
              style: textTheme.titleMedium?.copyWith(
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
                  color: customColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: customColors.borderDark),
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
                              size: 32, color: customColors.textMuted),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to upload',
                            style: textTheme.bodySmall?.copyWith(
                                color: customColors.textMuted),
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
                        'Save log',
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
