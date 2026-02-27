import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../alcohol/models/alcohol_model.dart';
import '../models/drink_model_dto.dart' as dto;

class ReviewEditorScreen extends StatefulWidget {
  final dto.DrinkLogModel? existingReview;
  final AlcoholModel alcohol;

  const ReviewEditorScreen({
    super.key,
    this.existingReview,
    required this.alcohol,
  });

  bool get isEdit => existingReview != null;

  @override
  State<ReviewEditorScreen> createState() => _ReviewEditorScreenState();
}

class _ReviewEditorScreenState extends State<ReviewEditorScreen> {
  late TextEditingController _noteController;
  double _rating = 0;

  // 🔁 Replace with your real auth source
  String get currentUserId => FirebaseAuth.instance.currentUser!.uid;
  String get currentUsername =>
      FirebaseAuth.instance.currentUser?.displayName ?? 'Anonymous';

  @override
  void initState() {
    super.initState();

    _noteController = TextEditingController(
      text: widget.existingReview?.note ?? '',
    );

    _rating = widget.existingReview?.rating ?? 0;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> saveReview() async {
    final userId = currentUserId;
    final alcohol = widget.alcohol;

    final reviewDocId = '${userId}_${alcohol.id}';

    final data = {
      'userId': userId,
      'alcoholId': alcohol.id,

      // ✅ REQUIRED FIELDS
      'alcoholName': alcohol.name,
      'alcoholType': alcohol.type,

      'username': currentUsername,
      'rating': _rating,
      'note': _noteController.text.trim(),
      'logKind': dto.LogKind.review.name,
      'updatedAt': Timestamp.now(),
    };

    final docRef =
        FirebaseFirestore.instance.collection('drink_logs').doc(reviewDocId);

    if (widget.isEdit) {
      await docRef.update(data);
    } else {
      await docRef.set({
        ...data,
        'createdAt': Timestamp.now(),
      });
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEdit ? 'Edit Review' : 'Write Review',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ⭐ Rating
            Row(
              children: [
                const Text('Rating'),
                const SizedBox(width: 12),
                DropdownButton<double>(
                  value: _rating,
                  items: List.generate(
                    6,
                    (i) => DropdownMenuItem(
                      value: i.toDouble(),
                      child: Text(i.toString()),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _rating = value);
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 📝 Review note
            TextField(
              controller: _noteController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Write your thoughts…',
                border: OutlineInputBorder(),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveReview,
                child: const Text('Save Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
