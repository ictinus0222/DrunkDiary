import 'package:flutter/material.dart';

enum DrinkReaction {
  loved('loved'),
  liked('liked'),
  nah('nah');

  final String value;
  const DrinkReaction(this.value);

  static DrinkReaction fromString(String? value) {
    return DrinkReaction.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DrinkReaction.liked,
    );
  }
}

class ReactionConfig {
  static String getLabel(DrinkReaction reaction) {
    switch (reaction) {
      case DrinkReaction.loved:
        return "Loved it";
      case DrinkReaction.liked:
        return "Liked it";
      case DrinkReaction.nah:
        return "Nah";
    }
  }

  static IconData getIcon(DrinkReaction reaction) {
    switch (reaction) {
      case DrinkReaction.loved:
        return Icons.favorite;
      case DrinkReaction.liked:
        return Icons.thumb_up_alt_outlined;
      case DrinkReaction.nah:
        return Icons.heart_broken_outlined;
    }
  }

  static Color getColor(DrinkReaction reaction) {
    switch (reaction) {
      case DrinkReaction.loved:
        return const Color(0xFFFFC107); // Gold/Amber
      case DrinkReaction.liked:
        return Colors.white70;
      case DrinkReaction.nah:
        return const Color(0xFFE53935); // Vibrant Red
    }
  }
}
