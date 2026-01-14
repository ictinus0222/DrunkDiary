import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drunk_diary/features/drink_logs/widgets/create_log_bottom_sheet.dart';
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

Future<void> createSharedDrinkLogs({
  required DrinkLogModel baseLog,
  required List<TaggedUser> taggedUsers,
}) async {
  final firestore = FirebaseFirestore.instance;

  // Create host log first
  final hostRef = await firestore
      .collection('drink_logs')
      .add(
    baseLog.copyWith(
      isShared: taggedUsers.isNotEmpty,
      createdByUserId: baseLog.userId,
      taggedUserIds: taggedUsers.map((u) => u.userId).toList(),
    ).toMap(),
  );

  final sourceLogId = hostRef.id;

  // Create logs for tagged users
  for (final user in taggedUsers) {
    final sharedLog = baseLog.copyWith(
      userId: user.userId,
      isShared: true,
      createdByUserId: baseLog.userId,
      taggedUserIds: taggedUsers.map((u) => u.userId).toList(),
      sourceLogId: sourceLogId,
    );

    await firestore.collection('drink_logs').add(sharedLog.toMap());
  }
}
