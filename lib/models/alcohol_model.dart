import 'package:cloud_firestore/cloud_firestore.dart';

class AlcoholModel {
  final String id;
  final String name;
  final String type;
  final String brand;
  final double abv;
  final String origin;
  final String description;
  final String imageUrl;

  AlcoholModel({
    required this.id,
    required this.name,
    required this.type,
    required this.brand,
    required this.abv,
    required this.origin,
    required this.description,
    required this.imageUrl,
  });

  factory AlcoholModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AlcoholModel(
      id: doc.id,
      name: data['name'],
      type: data['type'],
      brand: data['brand'],
      abv: (data['abv'] as num).toDouble(),
      origin: data['origin'],
      description: data['description'],
      imageUrl: data['imageUrl'],
    );
  }
}