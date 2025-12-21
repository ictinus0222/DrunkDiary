import 'package:cloud_firestore/cloud_firestore.dart';

class DrinkLogModel {
  final String id;
  final String userId;
  final String alcoholId;

  final String alcoholName;
  final String alcoholType;

  final double rating;
  final String? review;

  final String logType;        // diary | retro
  final String visibility;     // private | public

  final DateTime loggedAt;
  final DateTime? drankAt;

  DrinkLogModel({
    required this.id,
    required this.userId,
    required this.alcoholId,
    required this.alcoholName,
    required this.alcoholType,
    required this.rating,
    this.review,
    required this.logType,
    required this.visibility,
    required this.loggedAt,
    this.drankAt,
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
      review: data['review'],
      logType: data['logType'],
      visibility: data['visibility'],
      loggedAt: (data['loggedAt'] as Timestamp).toDate(),
      drankAt: data['drankAt'] != null
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
      'review': review,
      'logType': logType,
      'visibility': visibility,
      'loggedAt': Timestamp.fromDate(loggedAt),
      'drankAt':
      drankAt != null ? Timestamp.fromDate(drankAt!) : null,
    };
  }
}
