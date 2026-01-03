import 'user_model.dart';
import 'stats_model.dart';

class ProfileDataModel {
  final UserModel userData;
  final ProfileStatsModel stats;

  ProfileDataModel({
    required this.userData,
    required this.stats,
  });
}
