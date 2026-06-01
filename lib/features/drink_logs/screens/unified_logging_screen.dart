import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/app_theme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/reaction_config.dart';
import '../../alcohol/models/alcohol_model.dart';
import '../../alcohol/screens/bottle_selection_screen.dart';
import '../models/drink_model_dto.dart';
import '../../../core/theme/responsive_tokens.dart';
import '../../../core/theme/app_typography_roles.dart';
import '../../../core/widgets/responsive_layout.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/tag_friends_selector.dart';
import '../../profile/models/user_model.dart';

class UnifiedLoggingScreen extends ConsumerStatefulWidget {
  const UnifiedLoggingScreen({super.key});

  @override
  ConsumerState<UnifiedLoggingScreen> createState() => _UnifiedLoggingScreenState();
}

class _UnifiedLoggingScreenState extends ConsumerState<UnifiedLoggingScreen> {
  // State
  bool isCustom = true;
  AlcoholModel? selectedBottle;
  String? customName;
  File? selectedPhoto;
  DrinkReaction? selectedReaction;
  final TextEditingController noteController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  List<UserModel> taggedFriends = [];

  bool isSaving = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).extension<AppCustomColors>()!.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text('Take a Photo', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _executePickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _executePickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executePickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() => selectedPhoto = File(picked.path));
    }
  }

  Future<void> _selectBottle() async {
    final result = await Navigator.push<AlcoholModel>(
      context,
      MaterialPageRoute(builder: (_) => const BottleSelectionScreen()),
    );
    if (result != null) {
      setState(() {
        selectedBottle = result;
        isCustom = false;
      });
    }
  }

  Future<void> _save() async {
    if (isSaving) return;

    // Validation
    if (isCustom && (nameController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a drink name')),
      );
      return;
    }
    if (!isCustom && selectedBottle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a bottle')),
      );
      return;
    }

    setState(() => isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final isPrivate = userDoc.data()?['isPrivate'] as bool? ?? false;

      final log = DrinkLogModel(
        id: '',
        creatorId: user.uid,
        username: userDoc['username'] ?? 'Unknown',
        userPhotoUrl: userDoc['photoUrl'],
        alcoholId: isCustom ? null : selectedBottle!.id,
        alcoholName: isCustom ? nameController.text.trim() : selectedBottle!.name,
        alcoholType: isCustom ? 'Custom' : selectedBottle!.type,
        isCustom: isCustom,
        customName: isCustom ? nameController.text.trim() : null,
        reaction: selectedReaction,
        note: noteController.text.isNotEmpty ? noteController.text : null,
        logKind: LogKind.log,
        createdAt: DateTime.now(),
        isPrivate: isPrivate,
        acceptedParticipantIds: [user.uid],
        participantCount: 1,
      );

      final logRef = await FirebaseFirestore.instance.collection('drink_logs').add(log.toMap());

      // Batch write for participants and notifications
      final batch = FirebaseFirestore.instance.batch();

      // 1. Creator participant record
      final creatorParticipantRef = FirebaseFirestore.instance
          .collection('drink_log_participants')
          .doc('${logRef.id}_${user.uid}');
      
      batch.set(creatorParticipantRef, {
        'logId': logRef.id,
        'userId': user.uid,
        'status': 'accepted',
        'role': 'creator',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
      });

      // 2. Tagged friends participant records & notifications
      for (final friend in taggedFriends) {
        final participantRef = FirebaseFirestore.instance
            .collection('drink_log_participants')
            .doc('${logRef.id}_${friend.id}');

        batch.set(participantRef, {
          'logId': logRef.id,
          'userId': friend.id,
          'status': 'pending',
          'role': 'participant',
          'createdAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        });

        final notificationRef = FirebaseFirestore.instance
            .collection('users')
            .doc(friend.id)
            .collection('notifications')
            .doc('tag_${logRef.id}');

        batch.set(notificationRef, {
          'type': 'tag_request',
          'senderId': user.uid,
          'senderUsername': userDoc['username'] ?? 'Unknown',
          'senderProfileImage': userDoc['photoUrl'],
          'activityId': logRef.id,
          'itemName': log.alcoholName,
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
          'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        });
      }

      await batch.commit();

      if (selectedPhoto != null) {
        await _uploadPhoto(logRef, user.uid);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving log: $e')),
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
    } catch (e) {
      debugPrint('Error uploading photo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: customColors.deepCardBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('LOG A DRINK', style: AppTextStyles.appBarTitle),
        centerTitle: true,
      ),
      body: ResponsiveScaffoldBody(
        maxWidth: AppWidths.form,
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mode Selector
              Row(
                children: [
                  _ModeButton(
                    label: 'Custom',
                    isSelected: isCustom,
                    onTap: () => setState(() => isCustom = true),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _ModeButton(
                    label: 'Bottle',
                    isSelected: !isCustom,
                    onTap: () => setState(() => isCustom = false),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              if (isCustom) ...[
                Text('Drink Name', style: AppTypography.sectionLabel(context)),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: nameController,
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    hintText: 'What are you drinking?',
                    filled: true,
                    fillColor: customColors.cardBackground,
                  ),
                ),
              ] else ...[
                Text('Selected Bottle', style: AppTypography.sectionLabel(context)),
                const SizedBox(height: AppSpacing.sm),
                GestureDetector(
                  onTap: _selectBottle,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: customColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                      border: Border.all(color: customColors.borderDark),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.local_bar, color: colorScheme.primary),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            selectedBottle?.name ?? 'Tap to select a bottle',
                            style: AppTextStyles.body.copyWith(
                              color: selectedBottle == null ? customColors.textMuted : Colors.white,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white24),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Image Picker
              Text('Photo', style: AppTypography.sectionLabel(context)),
              const SizedBox(height: AppSpacing.sm),
              GestureDetector(
                onTap: _pickImage,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: customColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                      border: Border.all(color: customColors.borderDark),
                      image: selectedPhoto != null
                          ? DecorationImage(image: FileImage(selectedPhoto!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: selectedPhoto == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined, color: customColors.textMuted, size: 40),
                              const SizedBox(height: AppSpacing.sm),
                              Text('Add a photo', style: AppTextStyles.caption.copyWith(color: customColors.textMuted)),
                            ],
                          )
                        : null,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Reaction
              Text('How was it?', style: AppTypography.sectionLabel(context)),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: DrinkReaction.values.map((reaction) {
                  final isSelected = selectedReaction == reaction;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedReaction = reaction),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? ReactionConfig.getColor(reaction).withOpacity(0.2) : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? ReactionConfig.getColor(reaction) : customColors.borderDark,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              ReactionConfig.getIcon(reaction),
                              color: isSelected ? ReactionConfig.getColor(reaction) : customColors.textMuted,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ReactionConfig.getLabel(reaction),
                              style: AppTextStyles.caption.copyWith(
                                color: isSelected ? ReactionConfig.getColor(reaction) : customColors.textMuted,
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

              const SizedBox(height: AppSpacing.lg),

              // Notes
              Text('Notes', style: AppTypography.sectionLabel(context)),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: noteController,
                maxLines: 3,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  hintText: 'Any special memories?',
                  filled: true,
                  fillColor: customColors.cardBackground,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Tag Friends Selector
              TagFriendsSelector(
                selectedFriends: taggedFriends,
                onFriendsChanged: (friends) {
                  setState(() => taggedFriends = friends);
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('SAVE LOG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            border: Border.all(color: isSelected ? colorScheme.primary : customColors.borderDark),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: isSelected ? Colors.black : customColors.textMuted,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
