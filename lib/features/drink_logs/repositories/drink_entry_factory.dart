import '../models/drink_entry.dart';
import '../models/log_entry.dart';
import '../models/review_entry.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

DrinkEntry drinkEntryFromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  final kind = data['logKind'];

  if (kind == 'review') {
    return ReviewEntry.fromFirestore(doc);
  }

  return LogEntry.fromFirestore(doc);
}
