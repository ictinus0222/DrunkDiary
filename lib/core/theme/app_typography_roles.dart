import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/responsive_utils.dart';

/// 🔡 Semantic typographic roles for DrunkDiary.
/// Uses "Typographic Steps" for intentional platform scaling.
class AppTypography {
  static TextStyle _base({
    required double mobileSize,
    required double tabletSize,
    required FontWeight weight,
    double? height,
    double? letterSpacing,
    Color? color,
  }) {
    return GoogleFonts.dmSans(
      fontSize: mobileSize, // Base is mobile
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  // --- Semantic Roles ---

  static TextStyle feedTitle(BuildContext context) => _base(
        mobileSize: 18,
        tabletSize: 20,
        weight: FontWeight.bold,
        height: 1.2,
      ).copyWith(fontSize: context.isMobile ? 18 : 20);

  static TextStyle activityMetadata(BuildContext context) => _base(
        mobileSize: 12,
        tabletSize: 13,
        weight: FontWeight.w500,
        letterSpacing: 0.5,
        color: Colors.white54,
      ).copyWith(fontSize: context.isMobile ? 12 : 13);

  static TextStyle reviewBody(BuildContext context) => _base(
        mobileSize: 14,
        tabletSize: 16,
        weight: FontWeight.normal,
        height: 1.5,
      ).copyWith(fontSize: context.isMobile ? 14 : 16);

  static TextStyle profileUsername(BuildContext context) => _base(
        mobileSize: 14,
        tabletSize: 15,
        weight: FontWeight.w500,
        color: Colors.amber,
      ).copyWith(fontSize: context.isMobile ? 14 : 15);

  static TextStyle sectionLabel(BuildContext context) => _base(
        mobileSize: 12,
        tabletSize: 12,
        weight: FontWeight.bold,
        letterSpacing: 1.5,
        color: Colors.amber,
      );

  static TextStyle appBarTitle(BuildContext context) => _base(
        mobileSize: 16,
        tabletSize: 18,
        weight: FontWeight.w900,
        letterSpacing: 2.0,
      ).copyWith(fontSize: context.isMobile ? 16 : 18);
}
