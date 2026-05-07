import 'package:cloud_firestore/cloud_firestore.dart';

class DayActivityModel {
  final String id;
  final String userId;
  final DateTime date;
  final int cheersCount;
  final List<String> cheeredBy;
  final List<String> cheerAvatars;

  DayActivityModel({
    required this.id,
    required this.userId,
    required this.date,
    this.cheersCount = 0,
    this.cheeredBy = const [],
    this.cheerAvatars = const [],
  });

  factory DayActivityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      return DayActivityModel(
        id: doc.id,
        userId: '',
        date: DateTime.now(),
        cheerAvatars: [],
      );
    }

    return DayActivityModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      cheersCount: data['cheersCount'] as int? ?? 0,
      cheeredBy: List<String>.from(data['cheeredBy'] ?? []),
      cheerAvatars: (data['cheerAvatars'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'cheersCount': cheersCount,
      'cheeredBy': cheeredBy,
      'cheerAvatars': cheerAvatars,
    };
  }

  DayActivityModel copyWith({
    String? id,
    String? userId,
    DateTime? date,
    int? cheersCount,
    List<String>? cheeredBy,
    List<String>? cheerAvatars,
  }) {
    return DayActivityModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      cheersCount: cheersCount ?? this.cheersCount,
      cheeredBy: cheeredBy ?? this.cheeredBy,
      cheerAvatars: cheerAvatars ?? this.cheerAvatars,
    );
  }
}
