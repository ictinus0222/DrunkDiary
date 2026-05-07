import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendRequestStatus {
  pending,
  accepted,
  rejected,
  cancelled,
}

class FriendRequestModel {
  final String id;
  final String fromUserId;
  final String fromUsername;
  final String? fromPhotoUrl;
  final String toUserId;
  final FriendRequestStatus status;
  final DateTime createdAt;

  FriendRequestModel({
    required this.id,
    required this.fromUserId,
    required this.fromUsername,
    this.fromPhotoUrl,
    required this.toUserId,
    this.status = FriendRequestStatus.pending,
    required this.createdAt,
  });

  factory FriendRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendRequestModel(
      id: doc.id,
      fromUserId: data['fromUserId'] ?? '',
      fromUsername: data['fromUsername'] ?? '',
      fromPhotoUrl: data['fromPhotoUrl'],
      toUserId: data['toUserId'] ?? '',
      status: _parseStatus(data['status']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static FriendRequestStatus _parseStatus(dynamic value) {
    if (value == null) return FriendRequestStatus.pending;
    return FriendRequestStatus.values.firstWhere(
      (e) => e.name == value.toString(),
      orElse: () => FriendRequestStatus.pending,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'fromUsername': fromUsername,
      'fromPhotoUrl': fromPhotoUrl,
      'toUserId': toUserId,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
