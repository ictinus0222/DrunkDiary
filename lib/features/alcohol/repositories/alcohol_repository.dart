import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alcohol_model.dart';

class AlcoholRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<AlcoholModel>> searchAlcohols(String query) async {
    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();

    final snapshot = await _firestore
        .collection('alcohols')
        .orderBy('nameLowercase')
        .startAt([lowerQuery])
        .endAt(['$lowerQuery\uf8ff'])
        .limit(20)
        .get();

    return snapshot.docs.map((doc) => AlcoholModel.fromFirestore(doc)).toList();
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
