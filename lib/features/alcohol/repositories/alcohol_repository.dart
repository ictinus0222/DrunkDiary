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

    return snapshot.docs
        .map((doc) => AlcoholModel.fromFirestore(doc))
        .toList();
  }
}
