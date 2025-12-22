import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/drink_log_model.dart';

class DiaryTimelineScreen extends StatelessWidget {
  static const routeName = '/diaryTimeline';

  const DiaryTimelineScreen({super.key});

  Stream<List<DrinkLogModel>> _diaryLogsStream() {
    final user = FirebaseAuth.instance.currentUser!;

    return FirebaseFirestore.instance
        .collection('drink_logs')
        .where('userId', isEqualTo: user.uid)
        .where('logType', isEqualTo: 'diary')
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
          // if (snapshot.hasError) {
          //   return const Center(child: Text('Something went wrong'));
          // }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                textAlign: TextAlign.center,
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

          // Timeline list
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final log = logs[index];

              return Card(
                child: ListTile(
                  title: Text(log.alcoholName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rating: ${log.rating}'),
                      if (log.note != null && log.note!.isNotEmpty)
                        Text(
                          log.note!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  trailing: Text(
                    _formatDate(log.createdAt),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
