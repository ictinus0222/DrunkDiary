import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drunk_diary/core/providers/common_providers.dart';
import 'package:drunk_diary/features/alcohol/models/alcohol_model.dart';
import 'package:drunk_diary/features/drink_logs/models/drink_model_dto.dart';
import 'package:drunk_diary/features/drink_logs/repositories/drink_log_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final drinkLogRepositoryProvider = Provider((ref) => DrinkLogRepository());

/// Central stream of all user logs (Logs + Reviews)
final drinkLogsProvider = StreamProvider<List<DrinkLogModel>>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return Stream.value([]);
  
  final repository = ref.watch(drinkLogRepositoryProvider);
  return repository.watchLogsForUser(userId);
});

/// Global stream of all logs ever (Global Feed)
final allDrinkLogsProvider = StreamProvider<List<DrinkLogModel>>((ref) {
  final repository = ref.watch(drinkLogRepositoryProvider);
  return repository.watchAllLogs();
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

  // 1. Group logs by alcoholId
  final Map<String, List<DrinkLogModel>> grouped = {};
  for (var log in logs) {
    grouped.putIfAbsent(log.alcoholId, () => []).add(log);
  }

  // 2. Fetch/Resolve Alcohol Models for each ID
  final List<Map<String, dynamic>> shelfItems = [];
  
  for (final alcoholId in grouped.keys) {
    final alcohol = await ref.watch(alcoholCacheProvider(alcoholId).future);
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
        'lastInteraction': alcoholLogs.first.createdAt, // logs are descending
      });
    }
  }

  return shelfItems;
});
