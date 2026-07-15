import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFF1A73E8);
  static const secondary = Color(0xFF34A853);
  static const error = Color(0xFFEA4335);
  static const warning = Color(0xFFFBBC04);
  static const surface = Color(0xFFF5F5F5);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: secondary,
          error: error,
          surface: surface,
        ),
        appBarTheme: const AppBarTheme(centerTitle: true),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
}
