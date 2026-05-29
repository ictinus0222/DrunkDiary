import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../app/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/user_model.dart';
import '../providers/profile_providers.dart';

class EditProfileSheet extends ConsumerStatefulWidget {
  final UserModel user;

  const EditProfileSheet({super.key, required this.user});

  static Future<void> show(BuildContext context, UserModel user) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Edit Profile',
      pageBuilder: (context, animation, secondaryAnimation) {
        return EditProfileSheet(user: user);
      },
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutQuart)),
          child: child,
        );
      },
    );
  }

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _instagramController;
  late TextEditingController _bioController;

  File? _newProfileImage;
  File? _newCoverImage;
  final ImagePicker _picker = ImagePicker();

  bool _isSaving = false;
  String? _usernameError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.displayName);
    _usernameController = TextEditingController(text: widget.user.username);
    _instagramController = TextEditingController(text: widget.user.instagram ?? '');
    _bioController = TextEditingController(text: widget.user.bio ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _instagramController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  bool get _isDirty {
    return _nameController.text != widget.user.displayName ||
        _usernameController.text != widget.user.username ||
        _instagramController.text != (widget.user.instagram ?? '') ||
        _bioController.text != (widget.user.bio ?? '') ||
        _newProfileImage != null ||
        _newCoverImage != null;
  }

  Future<void> _pickImage(bool isProfile) async {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: customColors.deepCardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusDefault)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: Text('Take Photo', style: AppTextStyles.body.copyWith(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                if (picked != null) setState(() => isProfile ? _newProfileImage = File(picked.path) : _newCoverImage = File(picked.path));
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: Text('Choose from Gallery', style: AppTextStyles.body.copyWith(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                if (picked != null) setState(() => isProfile ? _newProfileImage = File(picked.path) : _newCoverImage = File(picked.path));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadImage(File file, String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    final newUsername = _usernameController.text.trim().toLowerCase();
    if (newUsername.isEmpty) {
      setState(() => _usernameError = 'Username cannot be empty');
      return;
    }

    setState(() {
      _isSaving = true;
      _usernameError = null;
    });

    try {
      final repo = ref.read(profileRepositoryProvider);
      
      if (newUsername != widget.user.username) {
        final isAvailable = await repo.isUsernameAvailable(widget.user.id, newUsername);
        if (!isAvailable) {
          setState(() {
            _isSaving = false;
            _usernameError = 'Username is already taken';
          });
          return;
        }
      }

      String? photoUrl = widget.user.photoUrl;
      String? coverUrl = widget.user.coverUrl;

      if (_newProfileImage != null) {
        photoUrl = await _uploadImage(_newProfileImage!, 'profiles/${widget.user.id}/profile.jpg');
        photoUrl = '$photoUrl?v=${DateTime.now().millisecondsSinceEpoch}';
      }

      if (_newCoverImage != null) {
        coverUrl = await _uploadImage(_newCoverImage!, 'profiles/${widget.user.id}/cover.jpg');
        coverUrl = '$coverUrl?v=${DateTime.now().millisecondsSinceEpoch}';
      }

      await repo.updateProfile(widget.user.id, {
        'displayName': _nameController.text.trim(),
        'displayNameLowercase': _nameController.text.trim().toLowerCase(),
        'username': newUsername,
        'usernameLowercase': newUsername,
        'instagram': _instagramController.text.trim(),
        'bio': _bioController.text.trim(),
        'photoUrl': photoUrl,
        'coverUrl': coverUrl,
      });

      ref.invalidate(profileDataProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving profile: $e', style: AppTextStyles.body)));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _handleCancel() {
    if (_isDirty) {
      final customColors = Theme.of(context).extension<AppCustomColors>()!;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: customColors.deepCardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusDefault)),
          title: Text('Discard changes?', style: AppTextStyles.subtitle.copyWith(color: Colors.white)),
          content: Text('You have unsaved changes. Are you sure you want to discard them?', style: AppTextStyles.body.copyWith(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Keep Editing', style: AppTextStyles.body.copyWith(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text('Discard', style: AppTextStyles.body.copyWith(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, topPadding + AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _HeaderButton(
                  label: 'Cancel',
                  onPressed: _handleCancel,
                ),
                Text(
                  'Edit profile',
                  style: AppTextStyles.subtitle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                _HeaderButton(
                  label: 'Done',
                  onPressed: _handleSave,
                  isLoading: _isSaving,
                  isPrimary: true,
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // ── Media Section ──────────────────────────────────────────
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: () => _pickImage(false),
                        child: Container(
                          height: 240,
                          width: double.infinity,
                          decoration: BoxDecoration(color: customColors.cardBackground),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (_newCoverImage != null)
                                Image.file(_newCoverImage!, fit: BoxFit.cover)
                              else if (widget.user.coverUrl != null)
                                CachedNetworkImage(imageUrl: widget.user.coverUrl!, fit: BoxFit.cover, placeholder: (_, __) => Container(color: Colors.white12))
                              else
                                const Icon(Icons.image, color: Colors.white12, size: 48),
                              
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                                  ),
                                ),
                              ),
                              
                              const Center(
                                child: CircleAvatar(
                                  backgroundColor: Colors.black45,
                                  child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      Positioned(
                        bottom: -40,
                        left: AppSpacing.xl,
                        child: GestureDetector(
                          onTap: () => _pickImage(true),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, shape: BoxShape.circle),
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 44,
                                  backgroundColor: Colors.amber,
                                  backgroundImage: _newProfileImage != null
                                      ? FileImage(_newProfileImage!)
                                      : (widget.user.photoUrl != null ? CachedNetworkImageProvider(widget.user.photoUrl!) : null) as ImageProvider?,
                                  child: (_newProfileImage == null && widget.user.photoUrl == null)
                                      ? const Icon(Icons.person, size: 40, color: Colors.black)
                                      : null,
                                ),
                                Positioned.fill(
                                  child: Container(
                                    decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 60),

                  // ── Form Fields ─────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      children: [
                        _EditField(label: 'Name', controller: _nameController, hint: 'Display Name'),
                        const _Divider(),
                        _EditField(
                          label: 'Username',
                          controller: _usernameController,
                          hint: 'username',
                          errorText: _usernameError,
                          onChanged: (_) => setState(() => _usernameError = null),
                        ),
                        const _Divider(),
                        _EditField(label: 'Instagram', controller: _instagramController, hint: '@handle'),
                        const _Divider(),
                        _EditField(
                          label: 'Bio',
                          controller: _bioController,
                          hint: 'Tell the world about your vibes...',
                          maxLines: 4,
                          maxLength: 200,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isPrimary;

  const _HeaderButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onPressed,
      borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isPrimary ? Colors.amber.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
          border: Border.all(color: isPrimary ? Colors.amber.withValues(alpha: 0.3) : Colors.white10),
        ),
        child: isLoading
            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(
                label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isPrimary ? Colors.amber : Colors.white70,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final int? maxLines;
  final int? maxLength;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const _EditField({
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.maxLength,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  maxLines: maxLines,
                  maxLength: maxLength,
                  onChanged: onChanged,
                  style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: AppTextStyles.body.copyWith(color: Colors.white24),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    counterStyle: AppTextStyles.caption.copyWith(color: Colors.white24),
                  ),
                ),
                if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(errorText!, style: AppTextStyles.caption.copyWith(color: Colors.redAccent)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(color: Colors.white.withValues(alpha: 0.05), height: 1);
  }
}
