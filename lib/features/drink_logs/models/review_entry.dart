import 'package:cloud_firestore/cloud_firestore.dart';
import 'drink_entry.dart';

class ReviewEntry extends DrinkEntry {
  ReviewEntry({
    required super.id,
    required super.userId,
    required super.alcoholId,
    required super.username,
    super.userPhotoUrl,
    required super.alcoholName,
    required super.alcoholType,
    required double rating, // ⭐ required
    required String note,   // 📝 required
    required super.createdAt,
    super.photoUrl,
    super.photoUploadedAt,
  }) : super(
    rating: rating,
    note: note,
    logKind: LogKind.review,
  );

  factory ReviewEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ReviewEntry(
      id: doc.id,
      userId: data['userId'],
      alcoholId: data['alcoholId'],
      username: data['username'] ?? 'Unknown',
      userPhotoUrl: data['userPhotoUrl'],
      alcoholName: data['alcoholName'],
      alcoholType: data['alcoholType'],
      rating: (data['rating'] as num).toDouble(),
      note: data['note'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      photoUrl: data['photoUrl'],
      photoUploadedAt: data['photoUploadedAt'] != null
          ? (data['photoUploadedAt'] as Timestamp).toDate()
          : null,
    );
  }

  @override
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
      'logKind': 'review',
      'createdAt': Timestamp.fromDate(createdAt),
      'photoUrl': photoUrl,
      'photoUploadedAt': photoUploadedAt,
    };
  }
}
