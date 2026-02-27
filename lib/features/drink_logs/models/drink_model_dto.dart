import 'package:cloud_firestore/cloud_firestore.dart';

enum LogKind { log, review }

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

  final double? rating;
  final bool? isLiked;
  final String? note;

  final LogKind logKind;

  final DateTime createdAt;
  final DateTime? consumedAt;

  final String? photoUrl;
  final DateTime? photoUploadedAt;

  DrinkLogModel({
    required this.id,
    required this.userId,
    required this.alcoholId,
    required this.username,
    this.userPhotoUrl,
    required this.alcoholName,
    required this.alcoholType,
    this.rating,
    this.isLiked,
    this.note,
    required this.logKind,
    required this.createdAt,
    this.consumedAt,
    this.photoUrl,
    this.photoUploadedAt,
  });

  factory DrinkLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('DrinkLog document ${doc.id} has no data');
    }

    final Timestamp? createdAtTs = data['createdAt'] as Timestamp?;

    return DrinkLogModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      alcoholId: data['alcoholId'] as String? ?? '',
      username: data['username'] as String? ?? 'Unknown',
      userPhotoUrl: data['userPhotoUrl'] as String?,
      alcoholName: data['alcoholName'] as String? ?? 'Unknown drink',
      alcoholType: data['alcoholType'] as String? ?? 'unknown',
      rating: (data['rating'] as num?)?.toDouble(),
      isLiked: data['isLiked'] as bool?,
      note: data['note'] as String?,
      logKind: data['logKind'] == 'review' ? LogKind.review : LogKind.log,
      createdAt:
          createdAtTs?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
      consumedAt: (data['consumedAt'] as Timestamp?)?.toDate(),
      photoUrl: data['photoUrl'] as String?,
      photoUploadedAt: (data['photoUploadedAt'] as Timestamp?)?.toDate(),
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
      'isLiked': isLiked,
      'note': note,
      'logKind': logKind.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'consumedAt': consumedAt != null ? Timestamp.fromDate(consumedAt!) : null,
      'photoUrl': photoUrl,
      'photoUploadedAt': photoUploadedAt,
    };
  }

  DrinkLogModel copyWith({
    String? userId,
    String? username,
    String? userPhotoUrl,
    double? rating,
    bool? isLiked,
    String? note,
    String? visibility,
    LogKind? logKind,
  }) {
    return DrinkLogModel(
      id: id,
      userId: userId ?? this.userId,
      alcoholId: alcoholId,
      username: username ?? this.username,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      alcoholName: alcoholName,
      alcoholType: alcoholType,
      rating: rating ?? this.rating,
      isLiked: isLiked ?? this.isLiked,
      note: note ?? this.note,
      logKind: logKind ?? this.logKind,
      createdAt: createdAt,
      consumedAt: consumedAt,
      photoUrl: photoUrl,
      photoUploadedAt: photoUploadedAt,
    );
  }
}
