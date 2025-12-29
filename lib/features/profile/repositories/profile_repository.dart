import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/profile_data.dart';
import '../models/user_model.dart';
import '../services/profile_service_stats.dart';

class ProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<ProfileData> fetchMyProfile(String userId) async {
    // Fetch user document
    final userDoc =
    await _firestore.collection('users').doc(userId).get();

    final user = UserModel.fromFirestore(userDoc);

    // Fetch stats
    final stats = await ProfileStatsService.fetchStats(userId);

    // Combine & return
    return ProfileData(
      user: user,
      stats: stats,
    );
  }
}

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateProfileVisibility({
    required String userId,
    required bool isProfilePublic,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'isProfilePublic': isProfilePublic,
    });
  }
}
