import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FeatureFlags {
  FeatureFlags();

  factory FeatureFlags.fromFirestore(DocumentSnapshot doc) {
    return FeatureFlags();
  }
}

final featureFlagsProvider = StreamProvider<FeatureFlags>((ref) {
  return FirebaseFirestore.instance
      .collection('configs')
      .doc('app_flags')
      .snapshots()
      .map((snapshot) => FeatureFlags.fromFirestore(snapshot));
});
