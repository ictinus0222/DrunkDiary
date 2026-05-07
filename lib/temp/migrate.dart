import 'package:cloud_firestore/cloud_firestore.dart';

/// One-time migration to add isPrivate: false to old logs
Future<void> runLogMigration() async {
  print('🚀 Starting Migration...');
  final firestore = FirebaseFirestore.instance;
  
  // Fetch all logs from the collection
  final snapshot = await firestore.collection('drink_logs').get();
  
  final batch = firestore.batch();
  int count = 0;

  for (var doc in snapshot.docs) {
    final data = doc.data();
    // Check if the field is missing
    if (!data.containsKey('isPrivate')) {
      batch.update(doc.reference, {'isPrivate': false});
      count++;
    }
  }

  if (count > 0) {
    await batch.commit();
    print('✅ Successfully updated $count logs with isPrivate: false!');
  } else {
    print('✨ No logs needed migration (all have isPrivate field).');
  }
}
