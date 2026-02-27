import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/drink_model_dto.dart';

class DrinkLogRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================
  // 🍾 REVIEWS FOR ALCOHOL PAGE
  // (public by definition)
  // ============================
  Future<List<DrinkLogModel>> fetchReviewsForAlcohol(
    String alcoholId,
  ) async {
    final snapshot = await _firestore
        .collection('drink_logs')
        .where('alcoholId', isEqualTo: alcoholId)
        .where('logKind', isEqualTo: 'review')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();

    return snapshot.docs.map(DrinkLogModel.fromFirestore).toList();
  }

  // ============================
  // 👤 USER REVIEWS (PUBLIC PROFILE)
  // ============================
  Future<List<DrinkLogModel>> fetchReviewsForUser(
    String userId,
  ) async {
    final snapshot = await _firestore
        .collection('drink_logs')
        .where('userId', isEqualTo: userId)
        .where('logKind', isEqualTo: 'review')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map(DrinkLogModel.fromFirestore).toList();
  }

  // ============================
  // 📝 USER LOGS (PRIVATE TIMELINE)
  // ============================
  Future<List<DrinkLogModel>> fetchLogsForUser(
    String userId,
  ) async {
    final snapshot = await _firestore
        .collection('drink_logs')
        .where('userId', isEqualTo: userId)
        .where('logKind', isEqualTo: 'log')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map(DrinkLogModel.fromFirestore).toList();
  }

  // ============================
  // ➕ CREATE SINGLE LOG / REVIEW
  // ============================
  Future<void> createDrinkLog(
    DrinkLogModel log,
  ) async {
    await _firestore.collection('drink_logs').add(log.toMap());
  }
}
