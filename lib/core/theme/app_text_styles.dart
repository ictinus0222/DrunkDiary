import 'package:flutter/material.dart';

class AppTextStyles {
  // 🔹 Font Families
  static const String headingFontFamily = 'DMSans';
  static const String bodyFontFamily = 'DMSans';

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
  static const TextStyle caption = TextStyle(
    fontFamily: 'DMSans',
    fontSize: captionSize,
    fontWeight: FontWeight.w400,
    color: Colors.grey,
  );

  // Body text (default)
  static const TextStyle body = TextStyle(
    fontFamily: 'DMSans',
    fontSize: bodySize,
    fontWeight: FontWeight.w500,
  );

  // Card titles (Alcohol names)
  static const TextStyle title = TextStyle(
    fontFamily: 'DMSans',
    fontSize: titleSize,
    fontWeight: FontWeight.w600,
    height: 1.2, // prevents vertical overflow
  );

  // Subtitle / Smaller headers
  static const TextStyle subtitle = TextStyle(
    fontFamily: 'DMSans',
    fontSize: subtitleSize,
    fontWeight: FontWeight.w600,
  );

  // Section headings (e.g., "Taste Identity", "Recent Activity")
  static const TextStyle section = TextStyle(
    fontFamily: 'DMSans',
    fontSize: sectionSize,
    fontWeight: FontWeight.w700,
  );

  // AppBar (Already defined separately, keeping it consistent)
  static const TextStyle appBarTitle = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 22, // NOT 24 (matching user specification)
    letterSpacing: 2.0,
    height: 1.0, // critical for vertical alignment
  );
}
