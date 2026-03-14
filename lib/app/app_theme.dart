import 'package:flutter/material.dart';

class AppCustomColors extends ThemeExtension<AppCustomColors> {
  final Color cardBackground;
  final Color deepCardBackground;
  final Color borderLight;
  final Color borderDark;
  final Color textMuted;
  final Color success;
  final Color error;
  final Color warning;

  const AppCustomColors({
    required this.cardBackground,
    required this.deepCardBackground,
    required this.borderLight,
    required this.borderDark,
    required this.textMuted,
    required this.success,
    required this.error,
    required this.warning,
  });

  @override
  AppCustomColors copyWith({
    Color? cardBackground,
    Color? deepCardBackground,
    Color? borderLight,
    Color? borderDark,
    Color? textMuted,
    Color? success,
    Color? error,
    Color? warning,
  }) {
    return AppCustomColors(
      cardBackground: cardBackground ?? this.cardBackground,
      deepCardBackground: deepCardBackground ?? this.deepCardBackground,
      borderLight: borderLight ?? this.borderLight,
      borderDark: borderDark ?? this.borderDark,
      textMuted: textMuted ?? this.textMuted,
      success: success ?? this.success,
      error: error ?? this.error,
      warning: warning ?? this.warning,
    );
  }

  @override
  AppCustomColors lerp(ThemeExtension<AppCustomColors>? other, double t) {
    if (other is! AppCustomColors) return this;
    return AppCustomColors(
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      deepCardBackground: Color.lerp(deepCardBackground, other.deepCardBackground, t)!,
      borderLight: Color.lerp(borderLight, other.borderLight, t)!,
      borderDark: Color.lerp(borderDark, other.borderDark, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

class AppThemes {
  static final AppCustomColors darkCustomColors = AppCustomColors(
    cardBackground: const Color(0xFF1A1A1A),
    deepCardBackground: const Color(0xFF0F0F0F),
    borderLight: const Color(0xFFFFC107).withOpacity(0.3),
    borderDark: const Color(0xFF333333),
    textMuted: const Color(0xFFB0B0B0),
    success: Colors.green,
    error: Colors.red,
    warning: const Color(0xFFFFC107),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFFFC107), // Amber #FFC107
      brightness: Brightness.dark,
      primary: const Color(0xFFFFC107),
      secondary: const Color(0xFFFFC107),
      surface: const Color(0xFF1A1A1A),
    ),
    scaffoldBackgroundColor: const Color(0xFF0F0F0F),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF0F0F0F),
      selectedItemColor: Color(0xFFFFC107),
      unselectedItemColor: Color(0xFF666666),
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1A1A1A),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF333333), width: 1),
      ),
    ),
    iconTheme: const IconThemeData(
      color: Colors.white,
    ),
    extensions: <ThemeExtension<dynamic>>[
      darkCustomColors,
    ],
  );

  static final lightCustomColors = AppCustomColors(
    cardBackground: Colors.white,
    deepCardBackground: Colors.grey.shade100,
    borderLight: Colors.amber.shade200,
    borderDark: Colors.grey.shade300,
    textMuted: Colors.grey.shade600,
    success: Colors.green.shade600,
    error: Colors.red.shade600,
    warning: Colors.amber.shade600,
  );

  static final lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color.fromARGB(255, 255, 193, 7),
      brightness: Brightness.light,
      primary: Colors.amber.shade700,
      secondary: Colors.amberAccent.shade700,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFFFFFFFF),
    appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        )),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
    ),
    extensions: <ThemeExtension<dynamic>>[
      lightCustomColors,
    ],
  );
}
