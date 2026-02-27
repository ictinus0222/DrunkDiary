import '../../alcohol/models/alcohol_model.dart';
import '../../drink_logs/models/drink_model_dto.dart';

class ProfileStatsModel {
  final int totalLogs;
  final int uniqueBottles;
  final double averageRating;
  final String? favoriteType;
  final String? topRatedAlcohol;
  final List<AlcoholModel> recentAlcohols;
  final List<DrinkLogModel> recentLogs;

  ProfileStatsModel({
    required this.totalLogs,
    required this.uniqueBottles,
    required this.averageRating,
    this.favoriteType,
    this.topRatedAlcohol,
    this.recentAlcohols = const [],
    this.recentLogs = const [],
  });
}
