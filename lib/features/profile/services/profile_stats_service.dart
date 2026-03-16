import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drunk_diary/features/profile/models/stats_model.dart';

import '../../alcohol/models/alcohol_model.dart';
import '../../drink_logs/models/drink_model_dto.dart';

class ProfileStatsService {
  static Future<ProfileStatsModel> fetchStats(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('drink_logs')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    final items = snapshot.docs.map(DrinkLogModel.fromFirestore).toList();
    return computeStatsFromLogs(items);
  }

  static Future<ProfileStatsModel> computeStatsFromLogs(
      List<DrinkLogModel> items) async {
    final totalLogs = items.where((log) => log.logKind == LogKind.log).length;
    final Set<String> uniqueAlcohols = {};
    double ratingSum = 0.0;
    int ratingCount = 0;

    final Map<String, int> typeCountMap = {};
    String? topRatedAlcoholName;
    double maxRating = -1.0;

    final List<DrinkLogModel> recentLogs = [];
    final List<String> recentAlcoholIds = [];

    for (final log in items) {
      if (recentLogs.length < 5) {
        recentLogs.add(log);
      }

      if (!uniqueAlcohols.contains(log.alcoholId)) {
        uniqueAlcohols.add(log.alcoholId);
        if (recentAlcoholIds.length < 10) {
          recentAlcoholIds.add(log.alcoholId);
        }
      }

      typeCountMap[log.alcoholType] = (typeCountMap[log.alcoholType] ?? 0) + 1;

      if (log.rating != null) {
        ratingSum += log.rating!;
        ratingCount++;
        if (log.rating! > maxRating) {
          maxRating = log.rating!;
          topRatedAlcoholName = log.alcoholName;
        }
      }
    }

    String? favoriteType;
    if (typeCountMap.isNotEmpty) {
      favoriteType =
          typeCountMap.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    final double avgRating = ratingCount > 0 ? ratingSum / ratingCount : 0.0;

    // Fetch recent alcohols
    final List<AlcoholModel> recentAlcohols = [];
    if (recentAlcoholIds.isNotEmpty) {
      final alcoholsSnapshot = await FirebaseFirestore.instance
          .collection('alcohols')
          .where(FieldPath.documentId, whereIn: recentAlcoholIds)
          .get();

      final Map<String, AlcoholModel> alcoholMap = {
        for (var doc in alcoholsSnapshot.docs)
          doc.id: AlcoholModel.fromFirestore(doc)
      };

      for (var id in recentAlcoholIds) {
        if (alcoholMap.containsKey(id)) {
          recentAlcohols.add(alcoholMap[id]!);
        }
      }
    }

    return ProfileStatsModel(
      totalLogs: totalLogs,
      uniqueBottles: uniqueAlcohols.length,
      averageRating: avgRating,
      favoriteType: favoriteType,
      topRatedAlcohol: topRatedAlcoholName,
      recentLogs: recentLogs,
      recentAlcohols: recentAlcohols,
    );
  }
}
