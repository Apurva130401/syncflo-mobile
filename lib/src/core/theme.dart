import 'package:flutter/material.dart';
export '../widgets/navigation_drawer.dart';

class AppColors {
  static bool _isDark = true;

  static void updateTheme(Brightness brightness) {
    _isDark = brightness == Brightness.dark;
  }

  // Dark palette (existing warm neutrals/orange)
  static const Color _darkBackground = Color(0xFF121110);
  static const Color _darkSurface = Color(0xFF1A1817);
  static const Color _darkSurfaceLight = Color(0xFF262322);
  static const Color _darkBorder = Color(0xFF332F2D);
  static const Color _darkPrimary = Color(0xFFFF8C00); // Sales Orange
  static const Color _darkPrimaryDark = Color(0xFFE05A00);
  static const Color _darkPrimaryLight = Color(0xFFFFB84D);
  static const Color _darkAccent = Color(0xFFF59E0B);
  static const Color _darkAccentWarm = Color(0xFFEA580C);
  static const Color _darkSuccess = Color(0xFF10B981);
  static const Color _darkError = Color(0xFFEF4444);
  static const Color _darkWarning = Color(0xFFF59E0B);
  static const Color _darkInfo = Color(0xFFD97706);
  static const Color _darkText = Color(0xFFF3F4F6);
  static const Color _darkTextMuted = Color(0xFF9CA3AF);
  static const Color _darkTextSecondary = Color(0xFFD1D5DB);
  static const Color _darkTextInverse = Color(0xFF121110);

  // Light palette (Next.js dashboard light theme)
  static const Color _lightBackground = Color(0xFFFFFFFF);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightSurfaceLight = Color(0xFFF1F5F9); // Slate 100
  static const Color _lightBorder = Color(0xFFE2E8F0); // Slate 200
  static const Color _lightPrimary = Color(0xFF2563EB); // Vibrant Blue 600
  static const Color _lightPrimaryDark = Color(0xFF1D4ED8); // Blue 700
  static const Color _lightPrimaryLight = Color(0xFF60A5FA); // Blue 400
  static const Color _lightAccent = Color(0xFFF59E0B); // Amber 500
  static const Color _lightAccentWarm = Color(0xFFD97706);
  static const Color _lightSuccess = Color(0xFF10B981); // Emerald 500
  static const Color _lightError = Color(0xFFEF4444); // Red 500
  static const Color _lightWarning = Color(0xFFF59E0B);
  static const Color _lightInfo = Color(0xFF3B82F6);
  static const Color _lightText = Color(0xFF0F172A); // Slate 900
  static const Color _lightTextMuted = Color(0xFF64748B); // Slate 500
  static const Color _lightTextSecondary = Color(0xFF334155); // Slate 700
  static const Color _lightTextInverse = Color(0xFFFFFFFF); // White text on dark buttons

  // Dynamic getters
  static Color get background => _isDark ? _darkBackground : _lightBackground;
  static Color get surface => _isDark ? _darkSurface : _lightSurface;
  static Color get surfaceLight => _isDark ? _darkSurfaceLight : _lightSurfaceLight;
  static Color get border => _isDark ? _darkBorder : _lightBorder;
  static Color get primary => _isDark ? _darkPrimary : _lightPrimary;
  static Color get primaryDark => _isDark ? _darkPrimaryDark : _lightPrimaryDark;
  static Color get primaryLight => _isDark ? _darkPrimaryLight : _lightPrimaryLight;
  static Color get accent => _isDark ? _darkAccent : _lightAccent;
  static Color get accentWarm => _isDark ? _darkAccentWarm : _lightAccentWarm;
  static Color get success => _isDark ? _darkSuccess : _lightSuccess;
  static Color get error => _isDark ? _darkError : _lightError;
  static Color get warning => _isDark ? _darkWarning : _lightWarning;
  static Color get info => _isDark ? _darkInfo : _lightInfo;
  static Color get text => _isDark ? _darkText : _lightText;
  static Color get textMuted => _isDark ? _darkTextMuted : _lightTextMuted;
  static Color get textSecondary => _isDark ? _darkTextSecondary : _lightTextSecondary;
  static Color get textInverse => _isDark ? _darkTextInverse : _lightTextInverse;

  static Color get overlay => _isDark ? const Color(0xBF121110) : const Color(0xBFFFFFFF);
  static Color get shadow => _isDark ? const Color(0x80000000) : const Color(0x1F000000);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors._darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors._darkPrimary,
        secondary: AppColors._darkAccent,
        surface: AppColors._darkSurface,
        error: AppColors._darkError,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors._darkSurface,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors._darkText),
        titleTextStyle: TextStyle(
          color: AppColors._darkText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors._darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors._darkBorder),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors._darkBorder,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors._darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: AppColors._darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: AppColors._darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: AppColors._darkPrimary),
        ),
        labelStyle: TextStyle(color: AppColors._darkTextMuted),
        hintStyle: TextStyle(color: AppColors._darkTextMuted),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors._darkPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors._darkPrimary,
          foregroundColor: AppColors._darkTextInverse,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors._lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors._lightPrimary,
        secondary: AppColors._lightAccent,
        surface: AppColors._lightSurface,
        error: AppColors._lightError,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors._lightSurface,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors._lightText),
        titleTextStyle: TextStyle(
          color: AppColors._lightText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors._lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors._lightBorder),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors._lightBorder,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors._lightSurfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: AppColors._lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: AppColors._lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: AppColors._lightPrimary),
        ),
        labelStyle: TextStyle(color: AppColors._lightTextMuted),
        hintStyle: TextStyle(color: AppColors._lightTextMuted),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors._lightPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors._lightPrimary,
          foregroundColor: AppColors._lightTextInverse,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
