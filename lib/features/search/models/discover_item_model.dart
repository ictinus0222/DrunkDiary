import '../../alcohol/models/alcohol_model.dart';

class DiscoverItemModel {
  final AlcoholModel alcohol;
  final double globalRating;
  final int reviewCount;
  final bool hasUserLogged;
  final bool hasUserReviewed;

  DiscoverItemModel({
    required this.alcohol,
    required this.globalRating,
    required this.reviewCount,
    required this.hasUserLogged,
    required this.hasUserReviewed,
  });
}
