import '../../drink_logs/models/drink_model_dto.dart';
import '../../alcohol/models/alcohol_model.dart';

class ProfileStatsModel {
  final int totalLogs;
  final String? favoriteType;
  final String? topRatedAlcohol;
  final List<AlcoholModel> recentAlcohols;
  final List<DrinkLogModel> recentLogs;

  ProfileStatsModel({
    required this.totalLogs,
    this.favoriteType,
    this.topRatedAlcohol,
    required this.recentAlcohols,
    required this.recentLogs,
  });

  factory ProfileStatsModel.empty() => ProfileStatsModel(
        totalLogs: 0,
        recentAlcohols: [],
        recentLogs: [],
      );
}
