import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/day_activity_model.dart';

class DayActivityRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String collectionPath = 'activity_sessions';

  /// Watches a specific activity session for changes (cheers, etc.)
  Stream<DayActivityModel?> watchActivity(String activityId) {
    return _firestore
        .collection(collectionPath)
        .doc(activityId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return DayActivityModel.fromFirestore(snapshot);
    });
  }

  /// Toggles a cheers for a specific activity session
  Future<void> toggleCheers({
    required String activityId,
    required String userId,
    required DateTime date,
    required String activityOwnerId,
    String? senderUsername,
    String? senderProfileImage,
  }) async {
    final docRef = _firestore.collection(collectionPath).doc(activityId);
    final doc = await docRef.get();

    if (!doc.exists) {
      // Initialize the session document if it doesn't exist
      await docRef.set({
        'userId': activityOwnerId,
        'date': Timestamp.fromDate(date),
        'cheersCount': 1,
        'cheeredBy': [userId],
        'cheerAvatars': senderProfileImage != null ? [senderProfileImage] : [],
      });

      // Create notification for new cheer (if not self)
      if (userId != activityOwnerId && senderUsername != null) {
        await _createCheersNotification(
          receiverId: activityOwnerId,
          senderId: userId,
          senderUsername: senderUsername,
          senderProfileImage: senderProfileImage,
          activityId: activityId,
        );
      }
      return;
    }

    final data = doc.data() as Map<String, dynamic>;
    final cheeredBy = List<String>.from(data['cheeredBy'] ?? []);
    final isCheered = cheeredBy.contains(userId);

    if (isCheered) {
      await docRef.update({
        'cheersCount': FieldValue.increment(-1),
        'cheeredBy': FieldValue.arrayRemove([userId]),
        if (senderProfileImage != null) 'cheerAvatars': FieldValue.arrayRemove([senderProfileImage]),
      });
    } else {
      await docRef.update({
        'cheersCount': FieldValue.increment(1),
        'cheeredBy': FieldValue.arrayUnion([userId]),
        if (senderProfileImage != null) 'cheerAvatars': FieldValue.arrayUnion([senderProfileImage]),
      });

      // Create notification for added cheer (if not self)
      if (userId != activityOwnerId && senderUsername != null) {
        await _createCheersNotification(
          receiverId: activityOwnerId,
          senderId: userId,
          senderUsername: senderUsername,
          senderProfileImage: senderProfileImage,
          activityId: activityId,
        );
      }
    }
  }

  Future<void> _createCheersNotification({
    required String receiverId,
    required String senderId,
    required String senderUsername,
    String? senderProfileImage,
    required String activityId,
  }) async {
    await _firestore
        .collection('users')
        .doc(receiverId)
        .collection('notifications')
        .add({
      'type': 'cheers',
      'senderId': senderId,
      'senderUsername': senderUsername,
      'senderProfileImage': senderProfileImage,
      'activityId': activityId,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }
}
