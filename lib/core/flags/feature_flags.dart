import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FeatureFlags {
  final bool personalMeaningEnabled;

  FeatureFlags({this.personalMeaningEnabled = true});

  factory FeatureFlags.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FeatureFlags(
      personalMeaningEnabled: data['personal_meaning_enabled'] ?? true,
    );
  }
}

final featureFlagsProvider = StreamProvider<FeatureFlags>((ref) {
  return FirebaseFirestore.instance
      .collection('configs')
      .doc('app_flags')
      .snapshots()
      .map((snapshot) => FeatureFlags.fromFirestore(snapshot));
});
