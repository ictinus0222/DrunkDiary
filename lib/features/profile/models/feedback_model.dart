import 'package:cloud_firestore/cloud_firestore.dart';

enum FeedbackCategory {
  bug,
  feature,
  confusion,
}

class FeedbackModel {
  final String id;
  final String userId;
  final FeedbackCategory category;
  final String message;
  final String? screenshotUrl;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.message,
    this.screenshotUrl,
    required this.createdAt,
    required this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'category': category.name,
      'message': message,
      'screenshotUrl': screenshotUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'metadata': metadata,
    };
  }
}
