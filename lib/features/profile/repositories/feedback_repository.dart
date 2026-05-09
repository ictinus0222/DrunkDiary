import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/feedback_model.dart';
import '../../../core/analytics/performance_tracker.dart';

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  final performance = ref.watch(performanceTrackerProvider);
  return FeedbackRepository(
    FirebaseFirestore.instance,
    FirebaseStorage.instance,
    performance,
  );
});

class FeedbackRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final PerformanceTracker _performance;

  FeedbackRepository(this._firestore, this._storage, this._performance);

  Future<void> submitFeedback({
    required FeedbackModel feedback,
    File? screenshot,
  }) async {
    await _performance.trackDuration(
      operationName: 'submit_feedback',
      action: () async {
        String? screenshotUrl;

        // 1. Upload screenshot if exists
        if (screenshot != null) {
          final ref = _storage.ref().child('feedback/${feedback.id}.jpg');
          await ref.putFile(screenshot);
          screenshotUrl = await ref.getDownloadURL();
        }

        // 2. Save to Firestore
        final docRef = _firestore.collection('feedback').doc(feedback.id);
        await docRef.set(feedback.toMap()..['screenshotUrl'] = screenshotUrl);
      },
    );
  }
}
