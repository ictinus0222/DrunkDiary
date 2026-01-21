import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../alcohol/models/alcohol_model.dart';
import '../models/drink_log_model.dart';

class CreateLogBottomSheet extends StatefulWidget {
  final AlcoholModel alcohol;
  const CreateLogBottomSheet({super.key, required this.alcohol});

  @override
  State<CreateLogBottomSheet> createState() =>
      _CreateLogBottomSheetState();
}

class _CreateLogBottomSheetState
    extends State<CreateLogBottomSheet> {
  bool? liked; // 👍 true | 👎 false | null
  bool showNoteField = false;

  final TextEditingController noteController =
  TextEditingController();

  bool isSaving = false;
  bool isUploadingPhoto = false;

  File? selectedPhoto;
  final ImagePicker _picker = ImagePicker();

  List<TaggedUser> taggedUsers = [];

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
        rating: liked == true ? 1 : liked == false ? 0 : 0,
        note: noteController.text.isNotEmpty
            ? noteController.text
            : null,
        logKind: LogKind.log,
        createdAt: DateTime.now(),
        isShared: taggedUsers.isNotEmpty,
        createdByUserId:
        taggedUsers.isNotEmpty ? user.uid : null,
        taggedUserIds:
        taggedUsers.map((u) => u.userId).toList(),
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
  // TAG PEOPLE
  // =====================
  void _openTagPeopleSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _TagPeopleBottomSheet(),
    ).then((result) {
      if (result is List<TaggedUser>) {
        setState(() => taggedUsers = result);
      }
    });
  }

  Widget _buildUserChip(TaggedUser user) {
    return Chip(
      avatar: user.photoUrl != null
          ? CircleAvatar(
        backgroundImage:
        NetworkImage(user.photoUrl!),
      )
          : const CircleAvatar(
        child: Icon(Icons.person, size: 14),
      ),
      label: Text(user.username),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: () {
        setState(() {
          taggedUsers
              .removeWhere((u) => u.userId == user.userId);
        });
      },
    );
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
              style:
              TextStyle(fontSize: 12, color: Colors.grey),
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
                      color:
                      liked == true ? Colors.green : null,
                    ),
                    label: const Text('Like'),
                    onPressed: () =>
                        setState(() => liked = true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(
                      Icons.thumb_down,
                      color:
                      liked == false ? Colors.red : null,
                    ),
                    label: const Text('Dislike'),
                    onPressed: () =>
                        setState(() => liked = false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 👥 TAG PEOPLE
            const Text(
              'With',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _openTagPeopleSheet(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(12),
                  border:
                  Border.all(color: Colors.grey.shade700),
                ),
                child: taggedUsers.isEmpty
                    ? Row(
                  children: const [
                    Icon(Icons.person_add_alt_1_outlined,
                        size: 18),
                    SizedBox(width: 8),
                    Text('Tag people'),
                  ],
                )
                    : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: taggedUsers
                      .map(_buildUserChip)
                      .toList(),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // NOTE
            TextButton.icon(
              icon: const Icon(Icons.edit_note),
              label: const Text('Add a note'),
              onPressed: () =>
                  setState(() => showNoteField = !showNoteField),
            ),

            if (showNoteField) ...[
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                  'What made this moment memorable?',
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
                  border:
                  Border.all(color: Colors.grey.shade700),
                ),
                child: selectedPhoto == null
                    ? const Center(
                  child:
                  Icon(Icons.camera_alt_outlined),
                )
                    : ClipRRect(
                  borderRadius:
                  BorderRadius.circular(12),
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
                  child:
                  CircularProgressIndicator(
                      strokeWidth: 2),
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

// =====================
// TAGGED USER MODEL
// =====================
class TaggedUser {
  final String userId;
  final String username;
  final String? photoUrl;

  TaggedUser({
    required this.userId,
    required this.username,
    this.photoUrl,
  });
}

// =====================
// TAG PEOPLE SHEET
// =====================
class _TagPeopleBottomSheet extends StatefulWidget {
  const _TagPeopleBottomSheet();

  @override
  State<_TagPeopleBottomSheet> createState() =>
      _TagPeopleBottomSheetState();
}

class _TagPeopleBottomSheetState
    extends State<_TagPeopleBottomSheet> {
  final TextEditingController searchController =
  TextEditingController();

  final List<TaggedUser> selectedUsers = [];
  final List<TaggedUser> searchResults = [];
  bool isSearching = false;

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() => searchResults.clear());
      return;
    }

    setState(() => isSearching = true);

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username',
        isLessThanOrEqualTo: '$query\uf8ff')
        .limit(10)
        .get();

    final results = snapshot.docs.map((doc) {
      final data = doc.data();
      return TaggedUser(
        userId: doc.id,
        username: data['username'] ?? 'Unknown',
        photoUrl: data['photoUrl'],
      );
    }).toList();

    setState(() {
      searchResults
        ..clear()
        ..addAll(results);
      isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Tag people',
            style:
            TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: searchController,
            onChanged: _searchUsers,
            decoration: InputDecoration(
              hintText: 'Search by username',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 16),

          if (isSearching)
            const CircularProgressIndicator()
          else
            ListView.builder(
              shrinkWrap: true,
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final user = searchResults[index];
                final isSelected = selectedUsers
                    .any((u) => u.userId == user.userId);

                return ListTile(
                  leading: user.photoUrl != null
                      ? CircleAvatar(
                    backgroundImage:
                    NetworkImage(user.photoUrl!),
                  )
                      : const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(user.username),
                  trailing: isSelected
                      ? const Icon(Icons.check,
                      color: Colors.green)
                      : null,
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedUsers.removeWhere(
                                (u) => u.userId == user.userId);
                      } else {
                        selectedUsers.add(user);
                      }
                    });
                  },
                );
              },
            ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, selectedUsers),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}
