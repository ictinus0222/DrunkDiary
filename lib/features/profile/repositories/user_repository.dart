import 'package:cloud_firestore/cloud_firestore.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔐 Toggle profile visibility
  Future<void> updateProfileVisibility({
    required String userId,
    required bool isProfilePublic,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'isProfilePublic': isProfilePublic,
    });
  }
}
