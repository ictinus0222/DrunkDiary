import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String displayName;
  final String? photoUrl;
  final bool ageVerified;
  final DateTime createdAt;
  // Profile
  final String? bio;
  final String username;
  final String role;

  UserModel({
    required this.id,
    required this.displayName,
    this.photoUrl,
    required this.ageVerified,
    required this.createdAt,
    // Profile
    this.bio,
    required this.username,
    this.role = 'user',
  });

  factory UserModel.fromFirestore(DocumentSnapshot userDoc) {
    final userData = userDoc.data() as Map<String, dynamic>;

    return UserModel(
      id: userDoc.id,
      displayName: userData['displayName'] ?? '',
      photoUrl: userData['photoUrl'],
      ageVerified: userData['ageVerified'] ?? false,
      createdAt:
          (userData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      // Profile
      bio: userData['bio'],
      username: userData['username'] ?? '',
      role: userData['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'photoUrl': photoUrl,
      'ageVerified': ageVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      // Profile
      'bio': bio,
      'username': username,
      'role': role,
    };
  }
}
