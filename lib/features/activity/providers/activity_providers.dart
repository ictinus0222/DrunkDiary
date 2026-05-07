import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/day_activity_repository.dart';
import '../models/day_activity_model.dart';

final dayActivityRepositoryProvider = Provider((ref) => DayActivityRepository());

final dayActivityProvider = StreamProvider.family<DayActivityModel?, String>((ref, activityId) {
  final repository = ref.watch(dayActivityRepositoryProvider);
  return repository.watchActivity(activityId);
});
