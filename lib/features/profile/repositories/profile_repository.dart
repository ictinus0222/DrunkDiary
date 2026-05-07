import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/profile_data_model.dart';
import '../models/user_model.dart';
import '../models/stats_model.dart';

class ProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Logged in Profile (for current user)
  Future<ProfileDataModel> fetchUserProfile(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();

    final userData = UserModel.fromFirestore(userDoc);

    return ProfileDataModel(
      userData: userData,
      userStats: ProfileStatsModel.empty(),
    );
  } // Checked ☑️

  Future<void> updatePrivacySetting(String userId, bool isPrivate) async {
    // 1. Update user document
    await _firestore.collection('users').doc(userId).update({
      'isPrivate': isPrivate,
    });
    
    // 2. Update all user logs (Denormalized sync)
    final logsSnapshot = await _firestore.collection('drink_logs')
        .where('userId', isEqualTo: userId)
        .get();
        
    if (logsSnapshot.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (var doc in logsSnapshot.docs) {
        batch.update(doc.reference, {'isPrivate': isPrivate});
      }
      await batch.commit();
    }
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    // 1. Update user document
    await _firestore.collection('users').doc(userId).update(data);

    // 2. Denormalize if username or photoUrl changed
    if (data.containsKey('username') || data.containsKey('photoUrl')) {
      final updates = <String, dynamic>{};
      if (data.containsKey('username')) updates['username'] = data['username'];
      if (data.containsKey('photoUrl')) updates['userPhotoUrl'] = data['photoUrl'];

      final logsSnapshot = await _firestore.collection('drink_logs')
          .where('userId', isEqualTo: userId)
          .get();

      if (logsSnapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (var doc in logsSnapshot.docs) {
          batch.update(doc.reference, updates);
        }
        await batch.commit();
      }
    }
  }

  Future<bool> isUsernameAvailable(String userId, String username) async {
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    if (query.docs.isEmpty) return true;
    
    // If only document found is the current user, it's available (they're keeping their name)
    return query.docs.every((doc) => doc.id == userId);
  }
}
