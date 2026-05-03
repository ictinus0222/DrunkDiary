import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  // 🔹 Font Families
  static const String headingFontFamily = 'DM Sans';
  static const String bodyFontFamily = 'DM Sans';

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
  static TextStyle caption = GoogleFonts.dmSans(
    fontSize: captionSize,
    fontWeight: FontWeight.w400,
    color: Colors.grey,
  );

  // Body text (default)
  static TextStyle body = GoogleFonts.dmSans(
    fontSize: bodySize,
    fontWeight: FontWeight.w500,
  );

  // Card titles (Alcohol names)
  static TextStyle title = GoogleFonts.dmSans(
    fontSize: titleSize,
    fontWeight: FontWeight.w600,
    height: 1.2, // prevents vertical overflow
  );

  // Subtitle / Smaller headers
  static TextStyle subtitle = GoogleFonts.dmSans(
    fontSize: subtitleSize,
    fontWeight: FontWeight.w600,
  );

  // Section headings (e.g., "Taste Identity", "Recent Activity")
  static TextStyle section = GoogleFonts.dmSans(
    fontSize: sectionSize,
    fontWeight: FontWeight.w700,
  );

  // AppBar (Already defined separately, keeping it consistent)
  static TextStyle appBarTitle = GoogleFonts.dmSans(
    fontSize: 22, // NOT 24 (matching user specification)
    letterSpacing: 2.0,
    height: 1.0, // critical for vertical alignment
  );
}
