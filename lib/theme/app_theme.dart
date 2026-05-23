import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData dark() {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.gold,
      surface: AppColors.surface,
      error: Color(0xFFFF6B6B),
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Color(0xFFF4F4F4),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          side: BorderSide(color: AppColors.surfaceHigh),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceHigh,
        selectedColor: AppColors.primary,
        labelStyle: const TextStyle(color: Colors.white),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.gold),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.black,
      ),
      tabBarTheme: const TabBarThemeData(
        indicatorColor: AppColors.gold,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.silver,
      ),
    );
  }
}
