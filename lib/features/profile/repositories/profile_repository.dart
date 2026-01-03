import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/profile_data_model.dart';
import '../models/user_model.dart';
import '../services/profile_stats_service.dart';

class ProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Logged in Profile (for current user)
  Future<ProfileDataModel> fetchUserProfile(String userId) async {
    final userDoc =
    await _firestore.collection('users').doc(userId).get();

    final userData = UserModel.fromFirestore(userDoc);
    final stats = await ProfileStatsService.fetchStats(userId);

    return ProfileDataModel(
      userData: userData,
      stats: stats,
    );
  } // Checked ☑️

  /// 🌍 Public profile by username
  Future<ProfileDataModel?> fetchPublicProfileByUsername(
      String username,
      ) async {
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final user = UserModel.fromFirestore(query.docs.first);

    // Extra safety (rules already enforce this)
    if (!user.isProfilePublic) return null;

    final stats = await ProfileStatsService.fetchStats(user.id);

    return ProfileDataModel(
      userData: user,
      stats: stats,
    );
  }

  /// 🔍 Search public users (for unified search)
  Future<List<UserModel>> searchPublicUsers(String query) async {
    if (query.isEmpty) return [];

    final snapshot = await _firestore
        .collection('users')
        .where('isProfilePublic', isEqualTo: true)
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThan: '${query}z')
        .limit(20)
        .get();

    return snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .toList();
  }
}
