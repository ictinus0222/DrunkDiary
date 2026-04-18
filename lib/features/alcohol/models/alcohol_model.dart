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
  final String? subType;
  final int? volumeMl;
  final List<String> tags;
  final double avgRating;
  final int ratingCount;
  final int logCount;
  final bool isVerified;
  final bool isActive;
  final List<String> searchKeywords;
  final String? createdBy;
  final DateTime? createdAt;
  final String description;
  final String imageUrl;

  // Constructor:
  AlcoholModel({
    required this.id,
    required this.name,
    required this.type,
    this.subType,
    required this.brand,
    required this.abv,
    required this.origin,
    this.volumeMl,
    this.tags = const [],
    this.avgRating = 0.0,
    this.ratingCount = 0,
    this.logCount = 0,
    this.isVerified = true,
    this.isActive = true,
    this.searchKeywords = const [],
    this.createdBy,
    this.createdAt,
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
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      subType: data['subType'],
      brand: data['brand'] ?? '',
      abv: (data['abv'] as num?)?.toDouble() ?? 0.0,
      origin: data['country'] ?? data['origin'] ?? '',
      volumeMl: data['volumeMl'] as int?,
      tags: List<String>.from(data['tags'] ?? []),
      avgRating: (data['avgRating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: data['ratingCount'] as int? ?? 0,
      logCount: data['logCount'] as int? ?? 0,
      isVerified: data['isVerified'] as bool? ?? true,
      isActive: data['isActive'] as bool? ?? true,
      searchKeywords: List<String>.from(data['searchKeywords'] ?? []),
      createdBy: data['createdBy'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nameLowercase': name.toLowerCase(),
      'type': type,
      'subType': subType,
      'brand': brand,
      'abv': abv,
      'country': origin,
      'volumeMl': volumeMl,
      'tags': tags,
      'avgRating': avgRating,
      'ratingCount': ratingCount,
      'logCount': logCount,
      'isVerified': isVerified,
      'isActive': isActive,
      'searchKeywords': searchKeywords,
      'createdBy': createdBy,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'description': description,
      'imageUrl': imageUrl,
    };
  }
}