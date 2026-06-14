import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum FriendState {
  none,
  outgoingPending,
  incomingPending,
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
  // Onboarding Metadata
  final DateTime? onboardingCompletedAt;
  final String? onboardingVersion;
  final bool onboardingSkipped;
  final List<String> preferredDrinkCategories;
  final bool? initialPrivacyPreference;
  // Profile
  final String? bio;
  final String? instagram;
  final String username;
  final String usernameLowercase;
  final String role;
  final bool isPrivate;
  final FriendState friendState;

  // Social (Private fields with safe getters to prevent Null subtype errors)
  final List<String>? _friends;
  final List<String>? _pendingIncomingRequests;
  final List<String>? _pendingOutgoingRequests;
  final List<String>? _blockedUsers;
  final Map<String, DateTime>? _friendsSince;

  List<String> get friends => _friends ?? const [];
  List<String> get pendingIncomingRequests => _pendingIncomingRequests ?? const [];
  List<String> get pendingOutgoingRequests => _pendingOutgoingRequests ?? const [];
  List<String> get blockedUsers => _blockedUsers ?? const [];
  Map<String, DateTime> get friendsSince => _friendsSince ?? const {};

  UserModel({
    required this.id,
    required this.displayName,
    required this.displayNameLowercase,
    this.photoUrl,
    this.coverUrl,
    required this.ageVerified,
    required this.createdAt,
    this.onboardingCompletedAt,
    this.onboardingVersion,
    this.onboardingSkipped = false,
    this.preferredDrinkCategories = const [],
    this.initialPrivacyPreference,
    // Profile
    this.bio,
    this.instagram,
    required this.username,
    required this.usernameLowercase,
    this.role = 'user',
    this.isPrivate = false,
    this.friendState = FriendState.none,
    List<String> friends = const [],
    List<String> pendingIncomingRequests = const [],
    List<String> pendingOutgoingRequests = const [],
    List<String> blockedUsers = const [],
    Map<String, DateTime> friendsSince = const {},
  })  : _friends = friends,
        _pendingIncomingRequests = pendingIncomingRequests,
        _pendingOutgoingRequests = pendingOutgoingRequests,
        _blockedUsers = blockedUsers,
        _friendsSince = friendsSince;

  factory UserModel.fromFirestore(DocumentSnapshot userDoc) {
    final userData = userDoc.data() as Map<String, dynamic>? ?? {};
    final id = userDoc.id;

    try {
      return UserModel(
        id: id,
      displayName: userData['displayName'] ?? '',
      displayNameLowercase: userData['displayNameLowercase'] ??
          (userData['displayName'] ?? '').toString().toLowerCase(),
      photoUrl: userData['photoUrl'],
      coverUrl: userData['coverUrl'],
      ageVerified: userData['ageVerified'] ?? false,
      createdAt:
          (userData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      onboardingCompletedAt:
          (userData['onboardingCompletedAt'] as Timestamp?)?.toDate(),
      onboardingVersion: userData['onboardingVersion'],
      onboardingSkipped: userData['onboardingSkipped'] ?? false,
      preferredDrinkCategories: _parseStringList(userData['preferredDrinkCategories']),
      initialPrivacyPreference: userData['initialPrivacyPreference'],
      // Profile
      bio: userData['bio'],
      instagram: userData['instagram'],
      username: userData['username'] ?? '',
      usernameLowercase: userData['usernameLowercase'] ??
          (userData['username'] ?? '').toString().toLowerCase(),
      role: userData['role'] ?? 'user',
      isPrivate: userData['isPrivate'] ?? false,
      friendState: _parseFriendState(userData['friendState']),
      friends: _parseStringList(userData['friends']),
      pendingIncomingRequests:
          _parseStringList(userData['pendingIncomingRequests']),
      pendingOutgoingRequests:
          _parseStringList(userData['pendingOutgoingRequests']),
      blockedUsers: _parseStringList(userData['blockedUsers']),
      friendsSince: _parseFriendsSince(userData['friendsSince']),
    );
    } catch (e, stack) {
      debugPrint('Error parsing UserModel for $id: $e');
      debugPrint(stack.toString());
      // Return a minimal valid model to prevent crashes
      return UserModel(
        id: id,
        username: 'unknown',
        usernameLowercase: 'unknown',
        displayName: 'Unknown User',
        displayNameLowercase: 'unknown user',
        ageVerified: false,
        createdAt: DateTime.now(),
      );
    }
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null || value is! List) return [];
    return value.map((e) => e.toString()).toList();
  }

  static Map<String, DateTime> _parseFriendsSince(dynamic value) {
    if (value == null || value is! Map) return {};
    return value.map((key, val) => MapEntry(
          key.toString(),
          (val as Timestamp).toDate(),
        ));
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
      'onboardingCompletedAt': onboardingCompletedAt != null ? Timestamp.fromDate(onboardingCompletedAt!) : null,
      'onboardingVersion': onboardingVersion,
      'onboardingSkipped': onboardingSkipped,
      'preferredDrinkCategories': preferredDrinkCategories,
      'initialPrivacyPreference': initialPrivacyPreference,
      // Profile
      'bio': bio,
      'instagram': instagram,
      'username': username,
      'usernameLowercase': usernameLowercase,
      'role': role,
      'isPrivate': isPrivate,
      'friendState': friendState.name,
      'friends': friends,
      'pendingIncomingRequests': pendingIncomingRequests,
      'pendingOutgoingRequests': pendingOutgoingRequests,
      'blockedUsers': blockedUsers,
      'friendsSince': friendsSince.map((key, value) => MapEntry(key, Timestamp.fromDate(value))),
    };
  }

  UserModel copyWith({
    String? displayName,
    String? displayNameLowercase,
    String? photoUrl,
    String? coverUrl,
    bool? ageVerified,
    DateTime? createdAt,
    DateTime? onboardingCompletedAt,
    String? onboardingVersion,
    bool? onboardingSkipped,
    List<String>? preferredDrinkCategories,
    bool? initialPrivacyPreference,
    String? bio,
    String? instagram,
    String? username,
    String? usernameLowercase,
    String? role,
    bool? isPrivate,
    FriendState? friendState,
    List<String>? friends,
    List<String>? pendingIncomingRequests,
    List<String>? pendingOutgoingRequests,
    List<String>? blockedUsers,
    Map<String, DateTime>? friendsSince,
  }) {
    return UserModel(
      id: id,
      displayName: displayName ?? this.displayName,
      displayNameLowercase: displayNameLowercase ?? this.displayNameLowercase,
      photoUrl: photoUrl ?? this.photoUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      ageVerified: ageVerified ?? this.ageVerified,
      createdAt: createdAt ?? this.createdAt,
      onboardingCompletedAt: onboardingCompletedAt ?? this.onboardingCompletedAt,
      onboardingVersion: onboardingVersion ?? this.onboardingVersion,
      onboardingSkipped: onboardingSkipped ?? this.onboardingSkipped,
      preferredDrinkCategories: preferredDrinkCategories ?? this.preferredDrinkCategories,
      initialPrivacyPreference: initialPrivacyPreference ?? this.initialPrivacyPreference,
      bio: bio ?? this.bio,
      instagram: instagram ?? this.instagram,
      username: username ?? this.username,
      usernameLowercase: usernameLowercase ?? this.usernameLowercase,
      role: role ?? this.role,
      isPrivate: isPrivate ?? this.isPrivate,
      friendState: friendState ?? this.friendState,
      friends: friends ?? this.friends,
      pendingIncomingRequests: pendingIncomingRequests ?? this.pendingIncomingRequests,
      pendingOutgoingRequests: pendingOutgoingRequests ?? this.pendingOutgoingRequests,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      friendsSince: friendsSince ?? this.friendsSince,
    );
  }
}
