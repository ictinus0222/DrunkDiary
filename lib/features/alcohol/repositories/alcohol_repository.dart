import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alcohol_model.dart';

class AlcoholRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<AlcoholModel>> searchAlcohols(String query) async {
    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();

    // Strategy: Search in the searchKeywords array
    final snapshot = await _firestore
        .collection('alcohols')
        .where('searchKeywords', arrayContains: lowerQuery)
        .limit(20)
        .get();

    // Fallback if no exact keyword match, use prefix search on name
    if (snapshot.docs.isEmpty) {
      final prefixSnapshot = await _firestore
          .collection('alcohols')
          .orderBy('nameLowercase')
          .startAt([lowerQuery])
          .endAt(['$lowerQuery\uf8ff'])
          .limit(20)
          .get();
      return prefixSnapshot.docs.map((doc) => AlcoholModel.fromFirestore(doc)).toList();
    }

    return snapshot.docs.map((doc) => AlcoholModel.fromFirestore(doc)).toList();
  }

  Future<void> createAlcohol(AlcoholModel alcohol) async {
    await _firestore.collection('alcohols').add(alcohol.toMap());
  }

  Future<List<AlcoholModel>> getAllAlcohols() async {
    final snapshot = await _firestore.collection('alcohols').get();
    return snapshot.docs.map((doc) => AlcoholModel.fromFirestore(doc)).toList();
  }

  Future<AlcoholModel?> getAlcoholById(String id) async {
    final doc = await _firestore.collection('alcohols').doc(id).get();
    if (!doc.exists) return null;
    return AlcoholModel.fromFirestore(doc);
  }
}
