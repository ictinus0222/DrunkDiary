import 'package:flutter/material.dart';

class AppColors {
  static const Color amber = Color(0xFFFFC107);
  static const Color darkBackground = Color(0xFF0F0F0F);
  static const Color cardGrey = Color(0xFF1A1A1A);
  static const Color borderGrey = Color(0xFF333333);
  static const Color textMuted = Color(0xFFB0B0B0);
  
  // Semantic Colors
  static const Color success = Colors.green;
  static const Color error = Colors.red;
  static const Color warning = Color(0xFFFFC107);

  static LinearGradient getAlcoholGradient(String type) {
    final lowerType = type.toLowerCase();
    List<Color> colors = [const Color(0xFF222222), const Color(0xFF0F0F0F)];

    if (lowerType.contains('beer')) {
      colors = [const Color(0xFF3D2B00), const Color(0xFF0F0F0F)]; // Amber/Gold
    } else if (lowerType.contains('wine')) {
      colors = [const Color(0xFF2D0A10), const Color(0xFF0F0F0F)]; // Burgundy
    } else if (lowerType.contains('whisky') || lowerType.contains('spirit') || lowerType.contains('rum') || lowerType.contains('brandy')) {
      colors = [const Color(0xFF331D0F), const Color(0xFF0F0F0F)]; // Cognac/Wood
    } else if (lowerType.contains('gin') || lowerType.contains('vodka') || lowerType.contains('tequila')) {
      colors = [const Color(0xFF0D1B2A), const Color(0xFF0F0F0F)]; // Deep Navy/Clear
    } else if (lowerType.contains('cocktail')) {
      colors = [const Color(0xFF1E0D2D), const Color(0xFF0F0F0F)]; // Purple/Night
    }

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }
}
