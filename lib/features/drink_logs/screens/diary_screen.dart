import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/drink_model_dto.dart';
import '../../drink_logs/widgets/drink_log_card.dart';

class DiaryTimelineScreen extends StatelessWidget {
  static const routeName = '/diaryTimeline';

  const DiaryTimelineScreen({super.key});

  Stream<List<DrinkLogModel>> _diaryLogsStream() {
    final user = FirebaseAuth.instance.currentUser!;

    return FirebaseFirestore.instance
        .collection('drink_logs')
        .where('userId', isEqualTo: user.uid)
        .where('logType', isEqualTo: 'diary') // ✅ diary-only
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => DrinkLogModel.fromFirestore(doc))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Diary 📖'),
      ),
      body: StreamBuilder<List<DrinkLogModel>>(
        stream: _diaryLogsStream(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.error_outline, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'Unable to load your diary right now.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please try again later.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          final logs = snapshot.data ?? [];

          // Empty state
          if (logs.isEmpty) {
            return const Center(
              child: Text(
                'No diary entries yet 🍻\nLog your first drink!',
                textAlign: TextAlign.center,
              ),
            );
          }

          // ✅ Diary timeline using shared card
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return DrinkLogCard(log: logs[index]);
            },
          );
        },
      ),
    );
  }
}
