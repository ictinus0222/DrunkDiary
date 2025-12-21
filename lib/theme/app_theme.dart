import 'package:flutter/material.dart';

class AppThemes {
  static final darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Color(0xFF8B5CF6),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: Color(0xFF060314),
    fontFamily: 'Roboto',
  );

  static final lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Color(0xFF8B5CF6),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Color(0xFFFFFFFF),
    fontFamily: 'Roboto',
  );
}