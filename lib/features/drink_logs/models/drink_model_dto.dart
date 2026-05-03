import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/reaction_config.dart';

enum LogKind { log, review }

// DrinkLogModel is one user interaction with one drink, not a static entity
// TODO: fix for when document is deleted, malformed or empty.
class DrinkLogModel {
  final String id;
  final String userId;
  final String? alcoholId; // Now nullable
  final String username;
  final String? userPhotoUrl;

  final String alcoholName;
  final String alcoholType;

  final bool isCustom; // NEW
  final String? customName; // NEW
  final String? customImageUrl; // NEW

  final double? rating;
  final DrinkReaction? reaction;
  final String? note;

  final LogKind logKind;

  final DateTime createdAt;
  final DateTime? consumedAt;

  final String? photoUrl;
  final DateTime? photoUploadedAt;

  DrinkLogModel({
    required this.id,
    required this.userId,
    this.alcoholId,
    required this.username,
    this.userPhotoUrl,
    required this.alcoholName,
    required this.alcoholType,
    this.isCustom = false,
    this.customName,
    this.customImageUrl,
    this.rating,
    this.reaction,
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
    final bool isCustom = data['isCustom'] as bool? ?? false;

    return DrinkLogModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      alcoholId: data['alcoholId'] as String?,
      username: data['username'] as String? ?? 'Unknown',
      userPhotoUrl: data['userPhotoUrl'] as String?,
      alcoholName: data['alcoholName'] as String? ?? 'Unknown drink',
      alcoholType: data['alcoholType'] as String? ?? 'unknown',
      isCustom: isCustom,
      customName: data['customName'] as String?,
      customImageUrl: data['customImageUrl'] as String?,
      rating: (data['rating'] as num?)?.toDouble(),
      reaction: data['reaction'] != null
          ? DrinkReaction.fromString(data['reaction'] as String)
          : (data['isLiked'] == true
              ? DrinkReaction.liked
              : (data['isLiked'] == false ? DrinkReaction.nah : null)),
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
      if (alcoholId != null) 'alcoholId': alcoholId,
      'username': username,
      'userPhotoUrl': userPhotoUrl,
      'alcoholName': alcoholName,
      'alcoholType': alcoholType,
      'isCustom': isCustom,
      if (customName != null) 'customName': customName,
      if (customImageUrl != null) 'customImageUrl': customImageUrl,
      'rating': rating,
      'reaction': reaction?.value,
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
    DrinkReaction? reaction,
    String? note,
    LogKind? logKind,
    bool? isCustom,
    String? customName,
    String? customImageUrl,
    String? alcoholId,
    String? alcoholName,
    String? alcoholType,
  }) {
    return DrinkLogModel(
      id: id,
      userId: userId ?? this.userId,
      alcoholId: alcoholId ?? this.alcoholId,
      username: username ?? this.username,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      alcoholName: alcoholName ?? this.alcoholName,
      alcoholType: alcoholType ?? this.alcoholType,
      isCustom: isCustom ?? this.isCustom,
      customName: customName ?? this.customName,
      customImageUrl: customImageUrl ?? this.customImageUrl,
      rating: rating ?? this.rating,
      reaction: reaction ?? this.reaction,
      note: note ?? this.note,
      logKind: logKind ?? this.logKind,
      createdAt: createdAt,
      consumedAt: consumedAt,
      photoUrl: photoUrl,
      photoUploadedAt: photoUploadedAt,
    );
  }
}
