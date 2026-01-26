import 'package:cloud_firestore/cloud_firestore.dart';
import 'drink_entry.dart';

class LogEntry extends DrinkEntry {
  final bool isShared;
  final String? createdByUserId;
  final List<String> taggedUserIds;
  final String? sourceLogId;

  LogEntry({
    required super.id,
    required super.userId,
    required super.alcoholId,
    required super.username,
    super.userPhotoUrl,
    required super.alcoholName,
    required super.alcoholType,
    required super.rating,
    super.note,
    required super.createdAt,
    super.photoUrl,
    super.photoUploadedAt,
    this.isShared = false,
    this.createdByUserId,
    this.taggedUserIds = const [],
    this.sourceLogId,
  }) : super(logKind: LogKind.log);

  factory LogEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return LogEntry(
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
      isShared: data['isShared'] == true,
      createdByUserId: data['createdByUserId'],
      taggedUserIds: List<String>.from(data['taggedUserIds'] ?? []),
      sourceLogId: data['sourceLogId'],
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
      'logKind': 'log',
      'createdAt': Timestamp.fromDate(createdAt),
      'photoUrl': photoUrl,
      'photoUploadedAt': photoUploadedAt,
      if (isShared) 'isShared': true,
      if (createdByUserId != null) 'createdByUserId': createdByUserId,
      if (taggedUserIds.isNotEmpty) 'taggedUserIds': taggedUserIds,
      if (sourceLogId != null) 'sourceLogId': sourceLogId,
    };
  }
}
