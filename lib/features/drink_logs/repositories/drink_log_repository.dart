import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/drink_log_model.dart';

class DrinkLogRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🌍 Public logs for Alcohol Detail Page
  Future<List<DrinkLogModel>> fetchPublicLogsForAlcohol(
      String alcoholId,
      ) async {
    final snapshot = await _firestore
        .collection('drink_logs')
        .where('alcoholId', isEqualTo: alcoholId)
        .where('visibility', isEqualTo: 'public')
        .get();

    return snapshot.docs
        .map((doc) => DrinkLogModel.fromFirestore(doc))
        .toList();
  }

  // 👤 Public logs for Public Profile
  Future<List<DrinkLogModel>> fetchPublicLogsForUser(
      String userId,
      ) async {
    final snapshot = await _firestore
        .collection('drink_logs')
        .where('userId', isEqualTo: userId)
        .where('visibility', isEqualTo: 'public')
        .get();

    return snapshot.docs
        .map((doc) => DrinkLogModel.fromFirestore(doc))
        .toList();
  }
}
  // 🌍 Public logs for Alcohol Detail Page
Future<List<DrinkLogModel>> fetchPublicLogsForAlcohol(
    String alcoholId,
    ) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('drink_logs')
      .where('alcoholId', isEqualTo: alcoholId)
      .where('visibility', isEqualTo: 'public')
      .orderBy('createdAt', descending: true)
      .limit(10)
      .get();

  return snapshot.docs
      .map((doc) => DrinkLogModel.fromFirestore(doc))
      .toList();
}
