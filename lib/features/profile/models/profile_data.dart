import 'user_model.dart';
import 'stats_model.dart';

class ProfileData {
  final UserModel user;
  final ProfileStats stats;

  ProfileData({
    required this.user,
    required this.stats,
  });
}
