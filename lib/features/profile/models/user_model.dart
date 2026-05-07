import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendState {
  none,
  pendingSent,
  pendingReceived,
  friends,
}

class UserModel {
  final String id;
  final String displayName;
  final String displayNameLowercase;
  final String? photoUrl;
  final String? coverUrl;
  final bool ageVerified;
  final DateTime createdAt;
  // Profile
  final String? bio;
  final String? instagram;
  final String username;
  final String usernameLowercase;
  final String role;
  final bool isPrivate;
  final FriendState friendState;

  UserModel({
    required this.id,
    required this.displayName,
    required this.displayNameLowercase,
    this.photoUrl,
    this.coverUrl,
    required this.ageVerified,
    required this.createdAt,
    // Profile
    this.bio,
    this.instagram,
    required this.username,
    required this.usernameLowercase,
    this.role = 'user',
    this.isPrivate = false,
    this.friendState = FriendState.none,
  });

  factory UserModel.fromFirestore(DocumentSnapshot userDoc) {
    final userData = userDoc.data() as Map<String, dynamic>;

    return UserModel(
      id: userDoc.id,
      displayName: userData['displayName'] ?? '',
      displayNameLowercase: userData['displayNameLowercase'] ?? (userData['displayName'] ?? '').toString().toLowerCase(),
      photoUrl: userData['photoUrl'],
      coverUrl: userData['coverUrl'],
      ageVerified: userData['ageVerified'] ?? false,
      createdAt:
          (userData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      // Profile
      bio: userData['bio'],
      instagram: userData['instagram'],
      username: userData['username'] ?? '',
      usernameLowercase: userData['usernameLowercase'] ?? (userData['username'] ?? '').toString().toLowerCase(),
      role: userData['role'] ?? 'user',
      isPrivate: userData['isPrivate'] ?? false,
      friendState: _parseFriendState(userData['friendState']),
    );
  }

  static FriendState _parseFriendState(dynamic value) {
    if (value == null) return FriendState.none;
    return FriendState.values.firstWhere(
      (e) => e.name == value.toString(),
      orElse: () => FriendState.none,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'displayNameLowercase': displayNameLowercase,
      'photoUrl': photoUrl,
      'coverUrl': coverUrl,
      'ageVerified': ageVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      // Profile
      'bio': bio,
      'instagram': instagram,
      'username': username,
      'usernameLowercase': usernameLowercase,
      'role': role,
      'isPrivate': isPrivate,
      'friendState': friendState.name,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? displayNameLowercase,
    String? photoUrl,
    String? coverUrl,
    bool? ageVerified,
    DateTime? createdAt,
    String? bio,
    String? instagram,
    String? username,
    String? usernameLowercase,
    String? role,
    bool? isPrivate,
    FriendState? friendState,
  }) {
    return UserModel(
      id: id,
      displayName: displayName ?? this.displayName,
      displayNameLowercase: displayNameLowercase ?? this.displayNameLowercase,
      photoUrl: photoUrl ?? this.photoUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      ageVerified: ageVerified ?? this.ageVerified,
      createdAt: createdAt ?? this.createdAt,
      bio: bio ?? this.bio,
      instagram: instagram ?? this.instagram,
      username: username ?? this.username,
      usernameLowercase: usernameLowercase ?? this.usernameLowercase,
      role: role ?? this.role,
      isPrivate: isPrivate ?? this.isPrivate,
      friendState: friendState ?? this.friendState,
    );
  }
}
