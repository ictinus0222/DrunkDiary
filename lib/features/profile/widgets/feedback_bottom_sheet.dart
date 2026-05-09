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
  final File? initialScreenshot;

  const FeedbackBottomSheet({
    super.key, 
    required this.currentScreen,
    this.initialScreenshot,
  });

  @override
  ConsumerState<FeedbackBottomSheet> createState() => _FeedbackBottomSheetState();
}

class _FeedbackBottomSheetState extends ConsumerState<FeedbackBottomSheet> {
  final _messageController = TextEditingController();
  FeedbackCategory _selectedCategory = FeedbackCategory.bug;
  File? _screenshot;
  bool _isSubmitting = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _screenshot = widget.initialScreenshot;
  }

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
        setState(() {
          _isSubmitting = false;
          _isSuccess = true;
        });

        // Show success for 2 seconds then close
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusDefault)),
      ),
      child: Stack(
        children: [
          // Main Content
          AnimatedOpacity(
            opacity: _isSubmitting || _isSuccess ? 0.3 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 32,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('SEND FEEDBACK', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 18, color: Colors.white54),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  
                  Row(
                    children: FeedbackCategory.values.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: ChoiceChip(
                          label: Text(cat.name.toUpperCase()),
                          selected: isSelected,
                          onSelected: (_) => _isSubmitting || _isSuccess ? null : setState(() => _selectedCategory = cat),
                          selectedColor: theme.primaryColor,
                          visualDensity: VisualDensity.compact,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _messageController,
                    maxLines: 2,
                    enabled: !_isSubmitting && !_isSuccess,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'What\'s on your mind?',
                      contentPadding: EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _isSubmitting || _isSuccess ? null : _pickImage,
                        child: Container(
                          height: 60,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: _screenshot != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(_screenshot!, fit: BoxFit.cover),
                                )
                              : const Icon(Icons.add_a_photo_outlined, color: Colors.white54, size: 20),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSubmitting || _isSuccess ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                          ),
                          child: const Text('SUBMIT'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Loading/Success Overlay
          if (_isSubmitting || _isSuccess)
            Positioned.fill(
              child: Container(
                color: const Color(0xFF1A1A1A), // Solid background color
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isSubmitting) ...[
                        const CircularProgressIndicator(color: Colors.amber),
                        const SizedBox(height: 16),
                        Text('Sending feedback...', style: AppTextStyles.body.copyWith(color: Colors.white70)),
                      ] else if (_isSuccess) ...[
                        const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
                        const SizedBox(height: 16),
                        Text('Thank you! Feedback sent.', style: AppTextStyles.body.copyWith(color: Colors.white)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
