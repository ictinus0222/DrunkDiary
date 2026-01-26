import 'package:cloud_firestore/cloud_firestore.dart';

enum LogKind {log, review}

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

  final LogKind logKind;

  final DateTime createdAt;
  final DateTime? consumedAt;

  final String? photoUrl;
  final DateTime? photoUploadedAt;

  final bool isShared;
  final String? createdByUserId;
  final List<String> taggedUserIds;
  final String? sourceLogId;


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
    required this.logKind,
    required this.createdAt,
    this.consumedAt,

    this.photoUrl,
    this.photoUploadedAt,

    this.isShared = false,
    this.createdByUserId,
    this.taggedUserIds = const [],
    this.sourceLogId,
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

      logKind: data['logKind'] == 'review'
        ? LogKind.review
      : LogKind.log,

      createdAt: createdAtTs != null
          ? createdAtTs.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
      consumedAt: data['consumedAt'] != null
          ? (data['consumedAt'] as Timestamp).toDate()
          : null,
      photoUrl: data['photoUrl'],
      photoUploadedAt: data['photoUploadedAt'] != null
          ? (data['photoUploadedAt'] as Timestamp).toDate()
          : null,

      isShared: data['isShared'] == true,
      createdByUserId: data['createdByUserId'],
      taggedUserIds: data['taggedUserIds'] != null
        ? List<String>.from(data['taggedUserIds'])
          : const [],
      sourceLogId: data['sourceLogId'],
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
      'logKind': logKind.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'consumedAt':
      consumedAt != null ? Timestamp.fromDate(consumedAt!) : null,
      'photoUrl': photoUrl,
      'photoUploadedAt': photoUploadedAt,

      if (isShared) 'isShared': true,
      if (createdByUserId != null) 'createdByUserId': createdByUserId,
      if (taggedUserIds.isNotEmpty) 'taggedUserIds': taggedUserIds,
      if (sourceLogId != null) 'sourceLogId': sourceLogId,
    };
  }
  DrinkLogModel copyWith({
    String? userId,
    String? username,
    String? userPhotoUrl,
    double? rating,
    String? note,
    String? visibility,
    bool? isShared,
    String? createdByUserId,
    List<String>? taggedUserIds,
    String? sourceLogId,
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
      note: note ?? this.note,
      logKind: logKind ?? this.logKind,
      createdAt: createdAt,
      consumedAt: consumedAt,
      photoUrl: photoUrl,
      photoUploadedAt: photoUploadedAt,
      isShared: isShared ?? this.isShared,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      taggedUserIds: taggedUserIds ?? this.taggedUserIds,
      sourceLogId: sourceLogId ?? this.sourceLogId,
    );
  }
}
