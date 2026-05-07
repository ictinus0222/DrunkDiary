import 'package:drunk_diary/features/drink_logs/providers/drink_logs_provider.dart';
import 'package:drunk_diary/features/drink_logs/models/drink_model_dto.dart';
import 'package:drunk_diary/features/profile/models/profile_data_model.dart';
import 'package:drunk_diary/features/profile/models/user_model.dart';
import 'package:drunk_diary/features/profile/repositories/profile_repository.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/common_providers.dart';

import '../repositories/friendship_repository.dart';
import '../models/friend_request_model.dart';
import '../models/stats_model.dart';
import '../../alcohol/repositories/alcohol_repository.dart';
import '../../alcohol/models/alcohol_model.dart';

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

  // Fetch basic user data
  final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
  final userData = UserModel.fromFirestore(userDoc);

  // Compute stats
  final stats = await _computeStats(ref, userId, logs);

  return ProfileDataModel(
    userData: userData,
    userStats: stats,
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

  final stats = await _computeStats(ref, userId, allLogs);

  return ProfileDataModel(
    userData: userData,
    userStats: stats,
  );
});

/// Internal helper to compute profile stats
Future<ProfileStatsModel> _computeStats(Ref ref, String userId, List<DrinkLogModel> allLogs) async {
  if (allLogs.isEmpty) return ProfileStatsModel.empty();

  // 1. Total Logs
  final totalLogs = allLogs.length;

  // 2. Favorite Type & Top Rated
  final Map<String, int> typeCounts = {};
  String? topRatedAlcohol;
  double maxRating = -1;

  for (final log in allLogs) {
    typeCounts[log.alcoholType] = (typeCounts[log.alcoholType] ?? 0) + 1;
    if (log.rating != null && log.rating! > maxRating) {
      maxRating = log.rating!;
      topRatedAlcohol = log.alcoholName;
    }
  }

  final favoriteType = typeCounts.isEmpty 
      ? null 
      : typeCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

  // 3. Recent Alcohols (Unique Bottles)
  final uniqueAlcoholIds = allLogs
      .map((l) => l?.alcoholId)
      .whereType<String>()
      .toSet()
      .take(10)
      .toList();

  final alcoholRepo = AlcoholRepository();
  final recentAlcohols = await Future.wait(
    uniqueAlcoholIds.map((id) => alcoholRepo.getAlcoholById(id))
  );

  return ProfileStatsModel(
    totalLogs: totalLogs,
    favoriteType: favoriteType,
    topRatedAlcohol: topRatedAlcohol,
    recentAlcohols: recentAlcohols.whereType<AlcoholModel>().toList(),
    recentLogs: allLogs.take(5).toList(),
  );
}
