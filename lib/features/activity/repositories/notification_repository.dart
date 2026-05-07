import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates a notification for a user
  Future<void> createNotification({
    required String receiverId,
    required NotificationModel notification,
  }) async {
    // Prevent self-notifications
    if (receiverId == notification.senderId) return;

    await _firestore
        .collection('users')
        .doc(receiverId)
        .collection('notifications')
        .add(notification.toFirestore());
  }

  /// Streams notifications for a specific user
  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList();
    });
  }

  /// Marks a specific notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// Marks all notifications for a user as read
  Future<void> markAllAsRead(String userId) async {
    final batch = _firestore.batch();
    final unread = await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }
}
