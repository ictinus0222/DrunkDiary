import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String displayName;
  final String? photoUrl;
  final String? coverUrl;
  final bool ageVerified;
  final DateTime createdAt;
  // Profile
  final String? bio;
  final String? instagram;
  final String username;
  final String role;
  final bool isPrivate;

  UserModel({
    required this.id,
    required this.displayName,
    this.photoUrl,
    this.coverUrl,
    required this.ageVerified,
    required this.createdAt,
    // Profile
    this.bio,
    this.instagram,
    required this.username,
    this.role = 'user',
    this.isPrivate = false,
  });

  factory UserModel.fromFirestore(DocumentSnapshot userDoc) {
    final userData = userDoc.data() as Map<String, dynamic>;

    return UserModel(
      id: userDoc.id,
      displayName: userData['displayName'] ?? '',
      photoUrl: userData['photoUrl'],
      coverUrl: userData['coverUrl'],
      ageVerified: userData['ageVerified'] ?? false,
      createdAt:
          (userData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      // Profile
      bio: userData['bio'],
      instagram: userData['instagram'],
      username: userData['username'] ?? '',
      role: userData['role'] ?? 'user',
      isPrivate: userData['isPrivate'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'photoUrl': photoUrl,
      'coverUrl': coverUrl,
      'ageVerified': ageVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      // Profile
      'bio': bio,
      'instagram': instagram,
      'username': username,
      'role': role,
      'isPrivate': isPrivate,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    String? coverUrl,
    bool? ageVerified,
    DateTime? createdAt,
    String? bio,
    String? instagram,
    String? username,
    String? role,
    bool? isPrivate,
  }) {
    return UserModel(
      id: id,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      ageVerified: ageVerified ?? this.ageVerified,
      createdAt: createdAt ?? this.createdAt,
      bio: bio ?? this.bio,
      instagram: instagram ?? this.instagram,
      username: username ?? this.username,
      role: role ?? this.role,
      isPrivate: isPrivate ?? this.isPrivate,
    );
  }
}
