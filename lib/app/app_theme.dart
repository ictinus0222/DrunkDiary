import 'package:flutter/material.dart';

class AppThemes {
  static final darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Color.fromARGB(1, 255, 193, 7),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: Color.fromARGB(1, 14, 14, 14),
    fontFamily: 'Roboto',
  );

  static final lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Color.fromARGB(1, 14, 14, 14),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Color(0xFFFFFFFF),
    fontFamily: 'Roboto',
  );
}