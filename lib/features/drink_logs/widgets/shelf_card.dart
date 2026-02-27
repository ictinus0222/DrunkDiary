import 'package:flutter/material.dart';
import '../../alcohol/models/alcohol_model.dart';
import '../../alcohol/screens/alcohol_detail_screen.dart';

class ShelfCard extends StatelessWidget {
  final AlcoholModel alcohol;
  final int logCount;
  final double avgRating;

  const ShelfCard({
    super.key,
    required this.alcohol,
    required this.logCount,
    required this.avgRating,
  });

  @override
  Widget build(BuildContext context) {
    // Using star for items that have a rating > 0, otherwise heart
    final bool hasRating = avgRating > 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AlcoholDetailScreen(alcohol: alcohol),
          ),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // The Box/Image
          Container(
            decoration: BoxDecoration(boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 15,
                offset: const Offset(0, 10),
              )
            ]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: AspectRatio(
                aspectRatio: 0.75,
                child: Image.network(
                  alcohol.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade900,
                    child: const Center(
                      child:
                          Icon(Icons.local_bar, size: 40, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // The floating badge
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade900,
              ),
              padding: const EdgeInsets.all(4),
              child: Icon(hasRating ? Icons.star : Icons.favorite,
                  color: Colors.amber, size: 12),
            ),
          )
        ],
      ),
    );
  }
}
