import 'package:flutter/material.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_spacing.dart';

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
      deepCardBackground:
          Color.lerp(deepCardBackground, other.deepCardBackground, t)!,
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
    borderLight: const Color(0xFFFFC107).withValues(alpha: 0.3),
    borderDark: const Color(0xFF333333),
    textMuted: const Color(0xFFB0B0B0),
    success: Colors.green,
    error: Colors.red,
    warning: const Color(0xFFFFC107),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    textTheme: TextTheme(
      bodyLarge: AppTextStyles.body,
      bodyMedium: AppTextStyles.body,
      bodySmall: AppTextStyles.caption,
      titleLarge: AppTextStyles.title,
      headlineSmall: AppTextStyles.section,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFFFC107), // Amber #FFC107
      brightness: Brightness.dark,
      primary: const Color(0xFFFFC107),
      secondary: const Color(0xFFFFC107),
      surface: const Color(0xFF1A1A1A),
    ),
    scaffoldBackgroundColor: const Color(0xFF0F0F0F),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF0F0F0F),
      selectedItemColor: Color(0xFFFFC107),
      unselectedItemColor: Color(0xFF666666),
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      enableFeedback: false,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF0F0F0F),
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: AppTextStyles.appBarTitle,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1A1A1A),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        side: const BorderSide(color: Color(0xFF333333), width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      contentPadding: const EdgeInsets.all(AppSpacing.lg),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        borderSide: const BorderSide(color: Color(0xFF333333)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        borderSide: const BorderSide(color: Color(0xFF333333)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        borderSide: const BorderSide(color: Color(0xFFFFC107), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      hintStyle: AppTextStyles.body.copyWith(color: const Color(0xFFB0B0B0).withValues(alpha: 0.3)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        ),
        backgroundColor: const Color(0xFFFFC107),
        foregroundColor: Colors.black,
        elevation: 0,
        textStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
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
    fontFamily: 'Inter',
    textTheme: TextTheme(
      bodyLarge: AppTextStyles.body,
      bodyMedium: AppTextStyles.body,
      bodySmall: AppTextStyles.caption,
      titleLarge: AppTextStyles.title,
      headlineSmall: AppTextStyles.section,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color.fromARGB(255, 255, 193, 7),
      brightness: Brightness.light,
      primary: Colors.amber.shade700,
      secondary: const Color(0xFFFFAB00),
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFFFFFFFF),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Colors.amber,
      unselectedItemColor: Colors.grey,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      enableFeedback: false,
    ),
    appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: AppTextStyles.appBarTitle),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.all(AppSpacing.lg),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        borderSide: const BorderSide(color: Color.fromARGB(255, 255, 193, 7), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      hintStyle: AppTextStyles.body.copyWith(color: Colors.grey.shade400),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        ),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        textStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
      ),
    ),
    extensions: <ThemeExtension<dynamic>>[
      lightCustomColors,
    ],
  );
}
