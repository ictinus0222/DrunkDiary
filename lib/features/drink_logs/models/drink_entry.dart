import 'package:cloud_firestore/cloud_firestore.dart';

enum LogKind { log, review }

abstract class DrinkEntry {
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

  final String? photoUrl;
  final DateTime? photoUploadedAt;

  const DrinkEntry({
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
    this.photoUrl,
    this.photoUploadedAt,
  });

  Map<String, dynamic> toMap();
}
