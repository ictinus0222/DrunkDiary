import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  // 🔹 Font Families
  static const String headingFontFamily = 'CategoriesElegant';
  static const String bodyFontFamily = 'Inter';

  // 🔹 Base
  static const double base = 14;

  // 🔹 Controlled scale (NOT strict golden ratio)
  static const double scale = 1.2;

  // 🔹 Sizes (manually balanced)
  static const double captionSize = 12;
  static const double bodySize = 14;
  static const double titleSize = 16;
  static const double subtitleSize = 18;
  static const double sectionSize = 20;
  static const double appBarSize = 28;

  // 🔹 Styles

  // Caption / metadata
  static TextStyle caption = GoogleFonts.inter(
    fontSize: captionSize,
    fontWeight: FontWeight.w400,
    color: Colors.grey,
  );

  // Body text (default)
  static TextStyle body = GoogleFonts.inter(
    fontSize: bodySize,
    fontWeight: FontWeight.w500,
  );

  // Card titles (Alcohol names)
  static TextStyle title = GoogleFonts.inter(
    fontSize: titleSize,
    fontWeight: FontWeight.w600,
    height: 1.2, // prevents vertical overflow
  );

  // Subtitle / Smaller headers
  static TextStyle subtitle = GoogleFonts.inter(
    fontSize: subtitleSize,
    fontWeight: FontWeight.w600,
  );

  // Section headings (e.g., "Taste Identity", "Recent Activity")
  static TextStyle section = GoogleFonts.inter(
    fontSize: sectionSize,
    fontWeight: FontWeight.w700,
  );

  // AppBar (Already defined separately, keeping it consistent)
  static TextStyle appBarTitle = const TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 22, // NOT 24 (matching user specification)
    letterSpacing: 2.0,
    height: 1.0, // critical for vertical alignment
  );
}
