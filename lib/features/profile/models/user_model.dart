import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String displayName;
  final String? photoUrl;
  final bool ageVerified;
  final DateTime createdAt;
  // Profile
  final String? bio;
  final bool isProfilePublic;
  final String username;

  UserModel({
    required this.id,
    required this.displayName,
    this.photoUrl,
    required this.ageVerified,
    required this.createdAt,
    // Profile
    this.bio,
    required this.isProfilePublic,
    required this.username,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      id: doc.id,
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      ageVerified: data['ageVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      // Profile
      bio: data['bio'],
      isProfilePublic: data['isProfilePublic'] ?? false,
      username: data['username'] ?? '',
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
      'isProfilePublic': isProfilePublic,
      'username': username,
    };
  }
}
