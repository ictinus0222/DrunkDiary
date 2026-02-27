import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/profile_data_model.dart';
import '../models/user_model.dart';
import '../services/profile_stats_service.dart';

class ProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Logged in Profile (for current user)
  Future<ProfileDataModel> fetchUserProfile(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();

    final userData = UserModel.fromFirestore(userDoc);
    final stats = await ProfileStatsService.fetchStats(userId);

    return ProfileDataModel(
      userData: userData,
      stats: stats,
    );
  } // Checked ☑️
}
