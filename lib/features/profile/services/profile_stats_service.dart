import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drunk_diary/features/profile/models/stats_model.dart';

class ProfileStatsService {
  static Future<ProfileStatsModel> fetchStats(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('drink_logs')
        .where('userId', isEqualTo: userId)
        .get();

    return _computeProfileStats(snapshot);
  } // Checked ☑️

  static ProfileStatsModel _computeProfileStats(QuerySnapshot snapshot) {
    final docs = snapshot.docs;

    final totalLogs = docs.length;
    final Set<String> uniqueAlcohols = {};
    double ratingSum = 0.0;
    int ratingCount = 0;

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
    } // Checked ☑️

    final double avgRating =
    ratingCount > 0 ? ratingSum / ratingCount : 0.0;

    return ProfileStatsModel(
      totalLogs: totalLogs,
      uniqueBottles: uniqueAlcohols.length,
      averageRating: avgRating,
    ); // Checked ☑️
  }

}