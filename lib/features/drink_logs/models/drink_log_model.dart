import 'package:cloud_firestore/cloud_firestore.dart';

// DrinkLogModel is one user interaction with one drink, not a static entity
// TODO: fix for when document is deleted, malformed or empty.
class DrinkLogModel {
  final String id;
  final String userId;
  final String alcoholId;
  final String username;
  final String? userPhotoUrl;

  final String alcoholName;
  final String alcoholType;

  final double rating;
  final String? note;

  final String logType;        // diary | log
  final String visibility;     // private | public

  final DateTime createdAt;
  final DateTime? consumedAt;

  DrinkLogModel({
    required this.id,
    required this.userId,
    required this.alcoholId,
    required this.username,
    this.userPhotoUrl,
    required this.alcoholName,
    required this.alcoholType,
    required this.rating,
    this.note,
    required this.logType,
    required this.visibility,
    required this.createdAt,
    this.consumedAt,
  });

  factory DrinkLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final Timestamp? createdAtTs = data['createdAt'] as Timestamp?;

    return DrinkLogModel(
      id: doc.id,
      userId: data['userId'] as String,
      alcoholId: data['alcoholId'] as String,
      username: data['username'] ?? 'Unknown',
      userPhotoUrl: data['userPhotoUrl'],
      alcoholName: data['alcoholName'] as String,
      alcoholType: data['alcoholType'] as String,
      rating: (data['rating'] as num).toDouble(),
      note: data['note'] as String?,
      logType: data['logType'] as String,
      visibility: data['visibility'] is String
          ? data['visibility']
          : (data['isPublic'] == true ? 'public' : 'private'),

      createdAt: createdAtTs != null
          ? createdAtTs.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
      consumedAt: data['consumedAt'] != null
          ? (data['consumedAt'] as Timestamp).toDate()
          : null,
    );

  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'alcoholId': alcoholId,
      'username': username,
      'userPhotoUrl': userPhotoUrl,
      'alcoholName': alcoholName,
      'alcoholType': alcoholType,
      'rating': rating,
      'note': note,
      'logType': logType,
      'visibility': visibility,
      'createdAt': Timestamp.fromDate(createdAt),
      'consumedAt':
      consumedAt != null ? Timestamp.fromDate(consumedAt!) : null,
    };
  }
}
