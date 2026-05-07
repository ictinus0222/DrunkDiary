import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drunk_diary/core/providers/common_providers.dart';
import 'package:drunk_diary/features/alcohol/models/alcohol_model.dart';
import 'package:drunk_diary/features/drink_logs/models/drink_model_dto.dart';
import 'package:drunk_diary/features/drink_logs/repositories/drink_log_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drunk_diary/features/profile/models/user_model.dart';
import 'package:drunk_diary/features/profile/providers/profile_providers.dart';

final drinkLogRepositoryProvider = Provider((ref) => DrinkLogRepository());

/// Central stream of all user logs (Logs + Reviews)
final drinkLogsProvider = StreamProvider<List<DrinkLogModel>>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return Stream.value([]);
  
  final repository = ref.watch(drinkLogRepositoryProvider);
  return repository.watchLogsForUser(userId);
});

/// Global stream of all logs ever (Global Feed - Unfiltered)
final allDrinkLogsProvider = StreamProvider<List<DrinkLogModel>>((ref) {
  final repository = ref.watch(drinkLogRepositoryProvider);
  return repository.watchAllLogs();
});

/// Filtered Global Feed (Option B - Denormalized)
/// Watches allDrinkLogsProvider and filters out logs from private users using the denormalized field.
final filteredAllDrinkLogsProvider = Provider<AsyncValue<List<DrinkLogModel>>>((ref) {
  final logsAsync = ref.watch(allDrinkLogsProvider);
  final currentUserId = ref.watch(userIdProvider);

  return logsAsync.whenData((allLogs) {
    if (allLogs.isEmpty) return [];

    return allLogs.where((log) {
      // 1. Owners see their own logs
      if (log.userId == currentUserId) return true;
      
      // 2. Others only see non-private logs
      return !log.isPrivate;
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
  
  return logsStream.map((logs) {
    // If it's the owner, show all logs.
    if (userId == currentUserId) return logs;
    
    // If it's someone else, hide private logs.
    return logs.where((log) => !log.isPrivate).toList();
  });
});
