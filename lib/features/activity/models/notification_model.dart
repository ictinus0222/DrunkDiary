import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String type; // e.g., 'cheers'
  final String senderId;
  final String senderUsername;
  final String? senderProfileImage;
  final String activityId;
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.type,
    required this.senderId,
    required this.senderUsername,
    this.senderProfileImage,
    required this.activityId,
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
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }
}
