
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drunk_diary/features/drink_logs/models/drink_log_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../drink_logs/widgets/drink_log_card.dart';

class TimelineScreen extends StatelessWidget {
  static const routeName = '/timeline';
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Timeline ⏳'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('drink_logs')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if(!snapshot.hasData ||  snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Your first drink memory is waiting 🍻'),
            );
          }

          final logs = snapshot.data!.docs
          .map((doc) => DrinkLogModel.fromFirestore(doc))
          .toList();

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              return DrinkLogCard(log: logs[index]);
          },
          );
        }
      ),
    );
  }
}
