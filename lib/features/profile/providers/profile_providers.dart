import 'package:drunk_diary/features/profile/models/profile_data_model.dart';
import 'package:drunk_diary/features/profile/models/user_model.dart';
import 'package:drunk_diary/features/profile/repositories/profile_repository.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/common_providers.dart';

import '../repositories/friendship_repository.dart';
import '../models/friend_request_model.dart';

final profileRepositoryProvider = Provider((ref) => ProfileRepository());
final friendshipRepositoryProvider = Provider((ref) => FriendshipRepository());

/// Stream of incoming friend requests for the current user
final incomingFriendRequestsProvider = StreamProvider<List<FriendRequestModel>>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('friend_requests')
      .where('toUserId', isEqualTo: userId)
      .where('status', isEqualTo: 'pending')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => FriendRequestModel.fromFirestore(doc))
          .toList());
});

/// Reactive Profile Data (User Data + Stats)
final profileDataProvider = FutureProvider<ProfileDataModel?>((ref) async {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return null;

  // Fetch basic user data once (or could also be a stream if needed)
  final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
  final userData = UserModel.fromFirestore(userDoc);

  return ProfileDataModel(
    userData: userData,
  );
});

/// Cache for user models to avoid redundant fetches in feed filtering
final userCacheProvider = FutureProvider.family<UserModel?, String>((ref, userId) async {
  final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
  if (!userDoc.exists) return null;
  return UserModel.fromFirestore(userDoc);
});

/// Fetch profile data for any user
final otherProfileDataProvider = FutureProvider.family<ProfileDataModel?, String>((ref, userId) async {
  final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
  if (!userDoc.exists) return null;
  final userData = UserModel.fromFirestore(userDoc);

  return ProfileDataModel(
    userData: userData,
  );
});

/// Resolves user models for all friends of the current user
final userFriendsProvider = FutureProvider<List<UserModel>>((ref) async {
  final profile = await ref.watch(profileDataProvider.future);
  final friendIds = profile?.userData.friends ?? [];
  if (friendIds.isEmpty) return [];

  // Firestore whereIn supports up to 30 items. If more, chunk or retrieve them.
  final limitedIds = friendIds.take(30).toList();

  final userDocs = await FirebaseFirestore.instance
      .collection('users')
      .where(FieldPath.documentId, whereIn: limitedIds)
      .get();

  return userDocs.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
});
