import 'package:drunk_diary/features/drink_logs/providers/drink_logs_provider.dart';
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

  // Watch the logs to trigger re-computation of stats
  final logsAsync = ref.watch(drinkLogsProvider);
  final logs = logsAsync.value ?? [];

  // Fetch basic user data once (or could also be a stream if needed)
  final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
  final userData = UserModel.fromFirestore(userDoc);
  print('Loaded profile for ${userData.id}. Friends: ${userData.friends.length}');

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
  print('Loaded other profile for ${userData.id}. Friends: ${userData.friends.length}');

  final repository = ref.watch(drinkLogRepositoryProvider);
  // For other users, we only care about their reviews or public logs if we were using Option B,
  // but for now we fetch all their logs to compute stats, 
  // and filtering happens at the UI/Feed level.
  final logs = await repository.fetchLogsForUser(userId);
  final reviews = await repository.fetchReviewsForUser(userId);
  final allLogs = [...logs, ...reviews]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return ProfileDataModel(
    userData: userData,
  );
});
