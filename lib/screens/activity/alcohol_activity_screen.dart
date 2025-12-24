import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/drink_log_model.dart';
import 'log_detail_screen.dart';

class AlcoholActivityScreen extends StatelessWidget {
  final String alcoholId;
  final String alcoholName;

  const AlcoholActivityScreen({
    super.key,
    required this.alcoholId,
    required this.alcoholName,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Not logged in")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(alcoholName),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('drink_logs')
            .where('userId', isEqualTo: user.uid)
            .where('alcoholId', isEqualTo: alcoholId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final logs = snapshot.data!.docs
              .map((doc) => DrinkLogModel.fromFirestore(doc))
              .toList();

          if (logs.isEmpty) {
            return const Center(child: Text("No logs yet 🍻"));
          }

          // 📊 Stats
          final logCount = logs.length;
          final ratedLogs =
          logs.where((l) => l.rating != null).toList();
          final avgRating = ratedLogs.isEmpty
              ? 0
              : ratedLogs
              .map((l) => l.rating!)
              .reduce((a, b) => a + b) /
              ratedLogs.length;

          return Column(
            children: [
              // 🔥 Stats Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "$logCount logs",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 18),
                        const SizedBox(width: 4),
                        Text(avgRating.toStringAsFixed(1)),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(),

              // 📜 Logs list
              Expanded(
                child: ListView.separated(
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final log = logs[index];

                    return ListTile(
                      title: Text(
                        log.rating != null
                            ? "Rated ${log.rating!.toStringAsFixed(1)} ★"
                            : "Logged a drink",
                      ),
                      subtitle: log.note != null &&
                          log.note!.isNotEmpty
                          ? Text(
                        log.note!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                          : null,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                LogDetailScreen(log: log),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
