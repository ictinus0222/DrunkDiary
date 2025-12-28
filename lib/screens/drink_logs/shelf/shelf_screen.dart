import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/alcohol_model.dart';
import '../../../widgets/shelf_card.dart';

class ShelfScreen extends StatefulWidget {
  static const routeName = '/shelf';
  const ShelfScreen({super.key});

  @override
  State<ShelfScreen> createState() => _ShelfScreenState();
}

class _ShelfScreenState extends State<ShelfScreen> {
  bool isLoading = true;

  List<AlcoholModel> shelfAlcohols = [];
  Map<String, int> logCounts = {};
  Map<String, double> avgRatings = {};

  @override
  void initState() {
    super.initState();
    fetchShelfData();
  }

Future<void> fetchShelfData() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final currentUserId = user.uid;

  // Fetch all logs from the current user (memory + diary)
  final logsSnapshot = await FirebaseFirestore.instance
  .collection('drink_logs')
  .where('userId', isEqualTo: currentUserId)
  .get();

  // Group logs by alcoholId
  final Map<String, List<QueryDocumentSnapshot>> groupedLogs = {};

  for (var log in logsSnapshot.docs) {
    final alcoholId =  log['alcoholId'];
    groupedLogs.putIfAbsent(alcoholId, () => []).add(log);
  }

  // Fetch alcohol docs + compute meta
  List<AlcoholModel> alcohols = [];
  Map<String, int> counts = {};
  Map<String, double> ratings = {};

  for (var entry in groupedLogs.entries) {
    final alcoholId = entry.key;
    final logs = entry.value;

    final alcoholDoc = await FirebaseFirestore.instance
    .collection('alcohols')
    .doc(alcoholId)
    .get();

    if (!alcoholDoc.exists) continue;

    alcohols.add(AlcoholModel.fromFirestore(alcoholDoc));

    counts[alcoholId] = logs.length;

    final ratingsList = logs
        .map((l) => (l['rating'] ?? 0).toDouble() ?? 0)
        .toList();

    final totalRating = ratingsList.isEmpty
        ? 0
        : ratingsList.reduce((a, b) => a + b);


    ratings[alcoholId] = totalRating / logs.length;
  }

  setState(() {
    shelfAlcohols = alcohols;
    logCounts = counts;
    avgRatings = ratings;
    isLoading = false;
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Shelf"),
        centerTitle: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : shelfAlcohols.isEmpty
          ? const Center(
        child: Text("Your shelf is empty 🍻"),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.7,
        ),
        itemCount: shelfAlcohols.length,
        itemBuilder: (context, index) {
          final alcohol = shelfAlcohols[index];
          final alcoholId = alcohol.id;

          return ShelfCard(
            alcohol: alcohol,
            logCount: logCounts[alcoholId] ?? 0,
            avgRating: avgRatings[alcoholId] ?? 0,
          );
        },
      ),
    );
  }

}
