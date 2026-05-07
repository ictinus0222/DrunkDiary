import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/notification_repository.dart';
import '../models/notification_model.dart';
import '../../../core/providers/common_providers.dart';

final notificationRepositoryProvider = Provider((ref) => NotificationRepository());

final notificationsStreamProvider = StreamProvider<List<NotificationModel>>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return Stream.value([]);

  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getNotificationsStream(userId);
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsStreamProvider).value ?? [];
  return notifications.where((n) => !n.isRead).length;
});
