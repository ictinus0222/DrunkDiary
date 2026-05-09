import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/feedback_model.dart';
import '../repositories/feedback_repository.dart';
import '../../../core/auth/auth_gate.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackBottomSheet extends ConsumerStatefulWidget {
  final String currentScreen;

  const FeedbackBottomSheet({super.key, required this.currentScreen});

  @override
  ConsumerState<FeedbackBottomSheet> createState() => _FeedbackBottomSheetState();
}

class _FeedbackBottomSheetState extends ConsumerState<FeedbackBottomSheet> {
  final _messageController = TextEditingController();
  FeedbackCategory _selectedCategory = FeedbackCategory.bug;
  File? _screenshot;
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _screenshot = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceInfo = DeviceInfoPlugin();
      String deviceModel = "Unknown";
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceModel = androidInfo.model;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceModel = iosInfo.utsname.machine;
      }

      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      
      final feedback = FeedbackModel(
        id: const Uuid().v4(),
        userId: userId,
        category: _selectedCategory,
        message: _messageController.text.trim(),
        createdAt: DateTime.now(),
        metadata: {
          'appVersion': packageInfo.version,
          'buildNumber': packageInfo.buildNumber,
          'currentScreen': widget.currentScreen,
          'deviceModel': deviceModel,
          'platform': Platform.operatingSystem,
        },
      );

      await ref.read(feedbackRepositoryProvider).submitFeedback(
            feedback: feedback,
            screenshot: _screenshot,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusDefault)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Feedback', style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.lg),
            
            // Category Selector
            Row(
              children: FeedbackCategory.values.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(cat.name.toUpperCase()),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    selectedColor: theme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'What\'s on your mind?',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Screenshot Preview
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                  border: Border.all(color: Colors.white24),
                ),
                child: _screenshot != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                        child: Image.file(_screenshot!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, color: Colors.white70),
                          SizedBox(height: 4),
                          Text('Add Photo', style: TextStyle(fontSize: 10, color: Colors.white54)),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Submit Feedback'),
            ),
          ],
        ),
      ),
    );
  }
}
