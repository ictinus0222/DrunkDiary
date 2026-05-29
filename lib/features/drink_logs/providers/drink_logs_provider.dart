import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drunk_diary/core/providers/common_providers.dart';
import 'package:drunk_diary/core/utils/visibility_resolver.dart';
import 'package:drunk_diary/features/alcohol/models/alcohol_model.dart';
import 'package:drunk_diary/features/drink_logs/models/drink_model_dto.dart';
import 'package:drunk_diary/features/drink_logs/repositories/drink_log_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drunk_diary/features/profile/models/user_model.dart';
import 'package:drunk_diary/features/profile/providers/profile_providers.dart';
import 'package:drunk_diary/core/analytics/analytics_service.dart';
import 'package:drunk_diary/core/analytics/performance_tracker.dart';

final drinkLogRepositoryProvider = Provider((ref) {
  final analytics = ref.watch(analyticsServiceProvider);
  final performance = ref.watch(performanceTrackerProvider);
  return DrinkLogRepository(analytics, performance);
});

/// Central stream of all user logs (Logs + Reviews)
final drinkLogsProvider = StreamProvider<List<DrinkLogModel>>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return Stream.value([]);
  
  final repository = ref.watch(drinkLogRepositoryProvider);
  return repository.watchLogsForUser(userId).map((list) {
    return list..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  });
});

/// Stream of accepted participant user profiles for a given log ID
final logParticipantsProvider = StreamProvider.family<List<UserModel>, String>((ref, logId) {
  return FirebaseFirestore.instance
      .collection('drink_log_participants')
      .where('logId', isEqualTo: logId)
      .where('status', isEqualTo: 'accepted')
      .snapshots()
      .asyncMap((snapshot) async {
        final uids = snapshot.docs.map((doc) => doc.data()['userId'] as String).toList();
        if (uids.isEmpty) return const <UserModel>[];

        // Fetch user profiles for these uids
        final userDocs = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: uids)
            .get();

        return userDocs.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
      });
});

/// Global stream of all logs ever (Global Feed - Unfiltered)
final allDrinkLogsProvider = StreamProvider<List<DrinkLogModel>>((ref) {
  final repository = ref.watch(drinkLogRepositoryProvider);
  return repository.watchAllLogs();
});

/// Friends-Only Feed (Friends Activity)
final friendsFeedProvider = StreamProvider<List<DrinkLogModel>>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return Stream.value([]);

  // Watch current user's profile to get friends list
  final profileAsync = ref.watch(profileDataProvider);
  final userData = profileAsync.value?.userData;
  final friends = userData?.friends ?? [];

  // Include self in the "Friends" feed so you see your own activity too
  final List<String> targetIds = [if (userId != null) userId, ...friends];

  if (targetIds.isEmpty) return Stream.value([]);

  final repository = ref.watch(drinkLogRepositoryProvider);
  final logsStream = repository.watchFriendsFeed(targetIds);

  return logsStream.map((logs) {
    final viewer = profileAsync.value?.userData;
    if (viewer == null) return [];

    final List<String> friends = viewer.friends;
    final List<String> blocked = viewer.blockedUsers;

    // Filter logs through VisibilityResolver (Friendship check + Blocking check)
    return logs.where((log) {
      if (log.userId == viewer.id) return true; // Always see your own logs
      if (blocked.contains(log.userId)) return false;
      
      // Since these are friends' logs, visibility check is straightforward
      return log.visibility != Visibility.closeFriends || friends.contains(log.userId);
    }).toList();
  });
});

/// Filtered Global Feed (Option B - Denormalized)
/// Watches allDrinkLogsProvider and filters out logs from private users using the denormalized field.
final filteredAllDrinkLogsProvider = Provider<AsyncValue<List<DrinkLogModel>>>((ref) {
  final logsAsync = ref.watch(allDrinkLogsProvider);
  final profileAsync = ref.watch(profileDataProvider);
  final viewer = profileAsync.value?.userData;

  return logsAsync.whenData((allLogs) {
    if (allLogs.isEmpty) return [];
    if (viewer == null) return allLogs.where((log) => !log.isPrivate).toList();

    return allLogs.where((log) {
      // 1. Owners see their own logs
      if (log.userId == viewer.id) return true;
      
      // 2. Blocked check
      if (viewer.blockedUsers.contains(log.userId)) return false;

      // 3. Visibility check
      return log.visibility == Visibility.public;
    }).toList();
  });
});

/// Map of Alcohol IDs to Alcohol Models (simulating local cache)
final alcoholCacheProvider = FutureProvider.family<AlcoholModel?, String>((ref, id) async {
  final doc = await FirebaseFirestore.instance.collection('alcohols').doc(id).get();
  if (!doc.exists) return null;
  return AlcoholModel.fromFirestore(doc);
});

/// Reactive Shelf Data (Unique Bottles with stats)
/// This provider will recompute whenever drinkLogsProvider emits new logs
final shelfAlcoholsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final logsAsync = ref.watch(drinkLogsProvider);
  final logs = logsAsync.value ?? [];
  
  if (logs.isEmpty) return [];

  // 1. Group logs by alcoholId (cataloged bottles only)
  final Map<String, List<DrinkLogModel>> grouped = {};
  for (var log in logs) {
    if (log.alcoholId != null) {
      grouped.putIfAbsent(log.alcoholId!, () => []).add(log);
    }
  }

  // 2. Fetch/Resolve Alcohol Models for each ID in parallel
  final List<String> alcoholIds = grouped.keys.toList();
  
  // Use ref.read for the futures to avoid excessive rebuilds inside the async body
  // and gather them all at once
  final List<AlcoholModel?> alcohols = await Future.wait(
    alcoholIds.map((id) => ref.read(alcoholCacheProvider(id).future))
  );

  final List<Map<String, dynamic>> shelfItems = [];
  
  for (int i = 0; i < alcoholIds.length; i++) {
    final alcoholId = alcoholIds[i];
    final alcohol = alcohols[i];
    
    if (alcohol != null) {
      final alcoholLogs = grouped[alcoholId]!;
      
      // Calculate stats for this bottle
      final standardLogs = alcoholLogs.where((l) => l.logKind == LogKind.log).toList();
      final reviewLogs = alcoholLogs.where((l) => l.logKind == LogKind.review && l.rating != null).toList();
      
      final double avgRating = reviewLogs.isEmpty 
          ? 0.0 
          : reviewLogs.map((l) => l.rating!).reduce((a, b) => a + b) / reviewLogs.length;

      shelfItems.add({
        'alcohol': alcohol,
        'logCount': standardLogs.length,
        'avgRating': avgRating,
        'lastInteraction': alcoholLogs.first.createdAt, // logs are already sorted descending
      });
    }
  }

  return shelfItems;
});

/// Stream of logs for a specific user, filtered by privacy if viewed by others.
final userDrinkLogsProvider = StreamProvider.family<List<DrinkLogModel>, String>((ref, userId) {
  final currentUserId = ref.watch(userIdProvider);
  final repository = ref.watch(drinkLogRepositoryProvider);
  
  final logsStream = repository.watchLogsForUser(userId);
  
  final profileAsync = ref.watch(profileDataProvider);
  final viewer = profileAsync.value?.userData;

  return logsStream.map((logs) {
    if (viewer == null) return logs.where((log) => !log.isPrivate).toList();
    
    return logs.where((log) {
      // 1. Self access
      if (log.userId == viewer.id) return true;

      // 2. Public profile activity is visible to all
      if (!log.isPrivate) return true;

      // 3. Private profile activity is visible only to friends
      // We use viewer.friends as the source of truth for the viewer's experience
      return viewer.friends.contains(log.userId);
    }).toList();
  });
});
