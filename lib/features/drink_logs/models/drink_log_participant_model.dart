import 'package:cloud_firestore/cloud_firestore.dart';

enum ParticipantStatus { pending, accepted, declined, expired }
enum ParticipantRole { creator, participant }

class DrinkLogParticipantModel {
  final String id; // Deterministic: {logId}_{userId}
  final String logId;
  final String userId;
  final ParticipantStatus status;
  final ParticipantRole role;
  final DateTime createdAt;
  final DateTime expiresAt;

  DrinkLogParticipantModel({
    required this.id,
    required this.logId,
    required this.userId,
    required this.status,
    required this.role,
    required this.createdAt,
    required this.expiresAt,
  });

  factory DrinkLogParticipantModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DrinkLogParticipantModel(
      id: doc.id,
      logId: data['logId'] ?? '',
      userId: data['userId'] ?? '',
      status: _parseStatus(data['status']),
      role: _parseRole(data['role']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 30)),
    );
  }

  static ParticipantStatus _parseStatus(dynamic value) {
    if (value == null) return ParticipantStatus.pending;
    return ParticipantStatus.values.firstWhere(
      (e) => e.name == value.toString(),
      orElse: () => ParticipantStatus.pending,
    );
  }

  static ParticipantRole _parseRole(dynamic value) {
    if (value == null) return ParticipantRole.participant;
    return ParticipantRole.values.firstWhere(
      (e) => e.name == value.toString(),
      orElse: () => ParticipantRole.participant,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'logId': logId,
      'userId': userId,
      'status': status.name,
      'role': role.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }
}
