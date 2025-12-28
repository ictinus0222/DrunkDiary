import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drunk_diary/models/stats_model.dart';
import 'package:flutter/material.dart';

class ProfileStatsService {
  static Future<ProfileStats> fetchStats(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('drink_logs')
        .where('userId', isEqualTo: userId)
        .get();

    return _computeProfileStats(snapshot);
  }

  static ProfileStats _computeProfileStats(QuerySnapshot snapshot) {
    final docs = snapshot.docs;

    final totalLogs = docs.length;
    final Set<String> uniqueAlcohols = {};
    double ratingSum = 0.0;
    int ratingCount = 0; // ✅ int, not double

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      final alcoholId = data['alcoholId'];
      if (alcoholId is String) {
        uniqueAlcohols.add(alcoholId);
      }

      final rating = data['rating'];
      if (rating is num) {
        ratingSum += rating.toDouble();
        ratingCount++;
      }
    }

    final double avgRating =
    ratingCount > 0 ? ratingSum / ratingCount : 0.0; // ✅ 0.0

    return ProfileStats(
      totalLogs: totalLogs,
      uniqueBottles: uniqueAlcohols.length,
      averageRating: avgRating,
    );
  }

}