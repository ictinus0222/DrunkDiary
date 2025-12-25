import 'package:cloud_firestore/cloud_firestore.dart';

// NOTES:
// This model represents one alcohol entry in the global database
// single source of truth for the application
// TODO: fix for when document is deleted, malformed or empty.
class AlcoholModel {
  final String id;
  final String name;
  final String type;
  final String brand;
  final double abv;
  final String origin;
  final String description;
  final String imageUrl;

  // Constructor:
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
// Factory constructor: Firestore returns a DocumentSnapshot
  // We're casting raw data into a map
  // and then map fields manually into our model
  factory AlcoholModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Field Mapping
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