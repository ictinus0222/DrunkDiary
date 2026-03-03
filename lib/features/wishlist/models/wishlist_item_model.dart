import 'package:cloud_firestore/cloud_firestore.dart';

class WishlistItemModel {
  final String id;
  final String userId;
  final String alcoholId;
  final String alcoholName;
  final String alcoholType;
  final String alcoholImageUrl;
  final String? note;
  final DateTime addedAt;

  WishlistItemModel({
    required this.id,
    required this.userId,
    required this.alcoholId,
    required this.alcoholName,
    required this.alcoholType,
    required this.alcoholImageUrl,
    this.note,
    required this.addedAt,
  });

  factory WishlistItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WishlistItemModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      alcoholId: data['alcoholId'] ?? '',
      alcoholName: data['alcoholName'] ?? 'Unknown',
      alcoholType: data['alcoholType'] ?? 'unknown',
      alcoholImageUrl: data['alcoholImageUrl'] ?? '',
      note: data['note'],
      addedAt: (data['addedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'alcoholId': alcoholId,
      'alcoholName': alcoholName,
      'alcoholType': alcoholType,
      'alcoholImageUrl': alcoholImageUrl,
      'note': note,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }
}
