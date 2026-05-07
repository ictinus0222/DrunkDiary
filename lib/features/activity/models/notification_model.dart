import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String type; // e.g., 'cheers'
  final String senderId;
  final String senderUsername;
  final String? senderProfileImage;
  final String activityId;
  final DateTime? activityDate; // NEW: The date of the session being cheered
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.type,
    required this.senderId,
    required this.senderUsername,
    this.senderProfileImage,
    required this.activityId,
    this.activityDate,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      type: data['type'] ?? 'cheers',
      senderId: data['senderId'] ?? '',
      senderUsername: data['senderUsername'] ?? '',
      senderProfileImage: data['senderProfileImage'],
      activityId: data['activityId'] ?? '',
      activityDate: (data['activityDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'senderId': senderId,
      'senderUsername': senderUsername,
      'senderProfileImage': senderProfileImage,
      'activityId': activityId,
      'activityDate': activityDate != null ? Timestamp.fromDate(activityDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }
}
