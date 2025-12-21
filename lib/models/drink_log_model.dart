import 'package:cloud_firestore/cloud_firestore.dart';

class DrinkLogModel {
  final String id;
  final String userId;
  final String alcoholId;

  final String alcoholName;
  final String alcoholType;

  final double rating;
  final String? note;

  final String logType;        // diary | retro
  final bool isPublic;     // private | public

  final DateTime createdAt;
  final DateTime? consumedAt;

  DrinkLogModel({
    required this.id,
    required this.userId,
    required this.alcoholId,
    required this.alcoholName,
    required this.alcoholType,
    required this.rating,
    this.note,
    required this.logType,
    required this.isPublic,
    required this.createdAt,
    this.consumedAt,
  });

  factory DrinkLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return DrinkLogModel(
      id: doc.id,
      userId: data['userId'],
      alcoholId: data['alcoholId'],
      alcoholName: data['alcoholName'],
      alcoholType: data['alcoholType'],
      rating: (data['rating'] as num).toDouble(),
      note: data['review'],
      logType: data['logType'],
      isPublic: data['visibility'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      consumedAt: data['consumedAt'] != null
          ? (data['drankAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'alcoholId': alcoholId,
      'alcoholName': alcoholName,
      'alcoholType': alcoholType,
      'rating': rating,
      'note': note,
      'logType': logType,
      'isPublic': isPublic,
      'createdAt': Timestamp.fromDate(createdAt),
      'consumedAt':
      consumedAt != null ? Timestamp.fromDate(consumedAt!) : null,
    };
  }
}
