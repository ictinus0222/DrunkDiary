import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String displayName;
  final String? photoUrl;
  final bool ageVerified;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.displayName,
    this.photoUrl,
    required this.ageVerified,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      id: doc.id,
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      ageVerified: data['ageVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'photoUrl': photoUrl,
      'ageVerified': ageVerified,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
