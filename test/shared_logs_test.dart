import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drunk_diary/features/drink_logs/models/drink_model_dto.dart';
import 'package:drunk_diary/features/drink_logs/models/drink_log_participant_model.dart';

// ignore: subtype_of_sealed_class
class FakeDocumentSnapshot implements DocumentSnapshot {
  @override
  final String id;
  final Map<String, dynamic>? _data;

  FakeDocumentSnapshot(this.id, this._data);

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic get(Object field) => _data?[field];

  @override
  dynamic operator [](Object field) => _data?[field];

  @override
  bool get exists => _data != null;

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();

  @override
  DocumentReference<Map<String, dynamic>> get reference => throw UnimplementedError();
}

void main() {
  group('DrinkLogModel Tests', () {
    test('toMap and fromFirestore serialization / deserialization', () {
      final now = DateTime.now();
      final originalModel = DrinkLogModel(
        id: 'log123',
        creatorId: 'user_creator',
        alcoholId: 'alcohol_whiskey',
        username: 'Akhil',
        userPhotoUrl: 'https://avatar.url',
        alcoholName: 'Glenfiddich 12',
        alcoholType: 'Whiskey',
        rating: 4.5,
        note: 'Loved it!',
        logKind: LogKind.log,
        createdAt: now,
        acceptedParticipantIds: ['user_creator', 'user_rahul'],
        participantCount: 2,
      );

      final map = originalModel.toMap();

      // Check values written to map
      expect(map['creatorId'], 'user_creator');
      expect(map['userId'], 'user_creator'); // backward compatibility
      expect(map['alcoholId'], 'alcohol_whiskey');
      expect(map['acceptedParticipantIds'], ['user_creator', 'user_rahul']);
      expect(map['participantCount'], 2);

      // Create snapshot from map
      final snapshot = FakeDocumentSnapshot('log123', map);
      final deserialized = DrinkLogModel.fromFirestore(snapshot);

      // Verify deserialized matches
      expect(deserialized.id, 'log123');
      expect(deserialized.creatorId, 'user_creator');
      expect(deserialized.userId, 'user_creator');
      expect(deserialized.alcoholId, 'alcohol_whiskey');
      expect(deserialized.username, 'Akhil');
      expect(deserialized.alcoholName, 'Glenfiddich 12');
      expect(deserialized.rating, 4.5);
      expect(deserialized.acceptedParticipantIds, ['user_creator', 'user_rahul']);
      expect(deserialized.participantCount, 2);
    });

    test('fromFirestore fallbacks when creatorId is missing but userId is present', () {
      final map = {
        'userId': 'legacy_user_id',
        'alcoholName': 'Macallan 18',
        'alcoholType': 'Whiskey',
        'createdAt': Timestamp.now(),
        'logKind': 'log',
      };

      final snapshot = FakeDocumentSnapshot('log999', map);
      final model = DrinkLogModel.fromFirestore(snapshot);

      expect(model.creatorId, 'legacy_user_id');
      expect(model.userId, 'legacy_user_id');
      expect(model.acceptedParticipantIds, isEmpty);
      expect(model.participantCount, 1);
    });
  });

  group('DrinkLogParticipantModel Tests', () {
    test('toMap and fromFirestore serialization / deserialization', () {
      final now = DateTime.now();
      final expires = now.add(const Duration(days: 7));

      final originalParticipant = DrinkLogParticipantModel(
        id: 'log123_user_rahul',
        logId: 'log123',
        userId: 'user_rahul',
        status: ParticipantStatus.pending,
        role: ParticipantRole.participant,
        createdAt: now,
        expiresAt: expires,
      );

      final map = originalParticipant.toMap();

      expect(map['logId'], 'log123');
      expect(map['userId'], 'user_rahul');
      expect(map['status'], 'pending');
      expect(map['role'], 'participant');

      final snapshot = FakeDocumentSnapshot('log123_user_rahul', map);
      final deserialized = DrinkLogParticipantModel.fromFirestore(snapshot);

      expect(deserialized.id, 'log123_user_rahul');
      expect(deserialized.logId, 'log123');
      expect(deserialized.userId, 'user_rahul');
      expect(deserialized.status, ParticipantStatus.pending);
      expect(deserialized.role, ParticipantRole.participant);
    });
  });
}
