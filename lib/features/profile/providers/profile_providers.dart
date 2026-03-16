import 'package:drunk_diary/features/drink_logs/providers/drink_logs_provider.dart';
import 'package:drunk_diary/features/profile/models/profile_data_model.dart';
import 'package:drunk_diary/features/profile/models/user_model.dart';
import 'package:drunk_diary/features/profile/repositories/profile_repository.dart';
import 'package:drunk_diary/features/profile/services/profile_stats_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/common_providers.dart';

final profileRepositoryProvider = Provider((ref) => ProfileRepository());

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

  // Compute stats reactively from the logs
  final stats = await ProfileStatsService.computeStatsFromLogs(logs);

  return ProfileDataModel(
    userData: userData,
    stats: stats,
  );
});
