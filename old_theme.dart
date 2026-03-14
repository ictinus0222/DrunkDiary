import 'package:flutter/material.dart';

class AppThemes {
  static final darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color.fromARGB(255, 255, 193, 7), // Amber
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color.fromARGB(255, 14, 14, 14),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.black,
      selectedItemColor: Colors.amber,
      unselectedItemColor: Colors.grey.shade600,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
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
