import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/drink_model_dto.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/analytics/performance_tracker.dart';

class DrinkLogRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics;
  final PerformanceTracker _performance;

  DrinkLogRepository(this._analytics, this._performance);

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
  // 📝 USER LOGS (PRIVATE DIARY)
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

  /// Real-time stream of all public interaction logs (Global Feed)
  Stream<List<DrinkLogModel>> watchAllLogs() {
    return _firestore
        .collection('drink_logs')
        .where('isPrivate', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(DrinkLogModel.fromFirestore).toList());
  }

  /// Real-time stream of all interaction logs for a user (Logs + Reviews)
  Stream<List<DrinkLogModel>> watchLogsForUser(String userId) {
    return _firestore
        .collection('drink_logs')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(DrinkLogModel.fromFirestore).toList());
  }

  /// Real-time stream of logs from a user's friends (Friends Feed)
  /// Limited to 10 friends for MVP due to Firestore 'whereIn' limits.
  Stream<List<DrinkLogModel>> watchFriendsFeed(List<String> friendIds) {
    if (friendIds.isEmpty) return Stream.value([]);
    
    // Take max 10 friends for MVP
    final limitedFriendIds = friendIds.take(10).toList();

    return _firestore
        .collection('drink_logs')
        .where('userId', whereIn: limitedFriendIds)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(DrinkLogModel.fromFirestore).toList());
  }

  // ============================
  // ➕ CREATE SINGLE LOG / REVIEW
  // ============================
  Future<void> createDrinkLog(
    DrinkLogModel log,
  ) async {
    _analytics.addBreadcrumb("Submitting drink log: ${log.alcoholName} (${log.logKind})");
    
    await _performance.trackDuration(
      operationName: 'create_drink_log',
      action: () async {
        try {
          await _firestore.collection('drink_logs').add(log.toMap());
        } catch (e) {
          String category = 'firestore_error';
          if (e.toString().contains('permission-denied')) {
            category = 'permission_denied';
          }
          
          await _analytics.logFailure(
            operation: 'create_drink_log',
            error: e,
            extraParams: {'error_category': category},
          );
          rethrow;
        }
      },
    );
  }
}
