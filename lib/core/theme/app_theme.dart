import 'package:flutter/material.dart';

/// Brand palette from the Letters to Heaven plan.
abstract final class AppColors {
  static const cream = Color(0xFFF7F1E8);
  static const parchment = Color(0xFFEDE4D4);
  static const cardinalRed = Color(0xFF9B1B2E);
  static const burgundy = Color(0xFF6E1423);
  static const antiqueGold = Color(0xFFC4A35A);
  static const softBlush = Color(0xFFE8C4C4);
  static const mutedOlive = Color(0xFF6B7A5A);
  static const ink = Color(0xFF2C2419);
  static const mutedInk = Color(0xFF5C5348);
}

/// Light theme: elegant serif titles + readable body (no runtime font fetch).
abstract final class AppTheme {
  static const _titleFamily = 'Georgia';
  static const _bodyFamily = 'Segoe UI';

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.cream,
      fontFamily: _bodyFamily,
      colorScheme: const ColorScheme.light(
        primary: AppColors.cardinalRed,
        onPrimary: Colors.white,
        secondary: AppColors.antiqueGold,
        onSecondary: AppColors.ink,
        surface: AppColors.parchment,
        onSurface: AppColors.ink,
        error: AppColors.burgundy,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.burgundy,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: _titleFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.burgundy,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.parchment,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.softBlush.withValues(alpha: 0.5)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.softBlush),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.softBlush),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.cardinalRed, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.parchment,
        indicatorColor: AppColors.softBlush,
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontFamily: _bodyFamily, fontSize: 11, color: AppColors.mutedInk),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.cardinalRed,
        foregroundColor: Colors.white,
      ),
      dividerColor: AppColors.softBlush,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.cardinalRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineLarge: const TextStyle(
          fontFamily: _titleFamily,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.burgundy,
        ),
        headlineMedium: const TextStyle(
          fontFamily: _titleFamily,
          fontSize: 26,
          color: AppColors.burgundy,
        ),
        titleLarge: const TextStyle(
          fontFamily: _titleFamily,
          fontSize: 22,
          color: AppColors.burgundy,
        ),
        titleMedium: const TextStyle(
          fontFamily: _bodyFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        bodyLarge: const TextStyle(
          fontFamily: _bodyFamily,
          fontSize: 16,
          height: 1.5,
          color: AppColors.ink,
        ),
        bodyMedium: const TextStyle(
          fontFamily: _bodyFamily,
          fontSize: 14,
          height: 1.45,
          color: AppColors.ink,
        ),
        bodySmall: const TextStyle(
          fontFamily: _bodyFamily,
          fontSize: 12,
          height: 1.4,
          color: AppColors.mutedInk,
        ),
        labelLarge: const TextStyle(
          fontFamily: _bodyFamily,
          fontWeight: FontWeight.w600,
          color: AppColors.cardinalRed,
        ),
      ),
    );
  }
}
