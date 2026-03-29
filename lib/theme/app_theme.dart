// ignore_for_file: avoid_redundant_argument_values
import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1DB954),
          secondary: Color(0xFF1ED760),
          surface: Color(0xFF121212),
          surfaceTint: Colors.transparent,
          surfaceContainerHighest: Color(0xFF2A2A2A),
          error: Color(0xFFCF6679),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF181818),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          foregroundColor: Colors.white,
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF121212),
          indicatorColor: Color(0xFF1DB954),
        ),
      );

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1AA34A),
          secondary: Color(0xFF1DB954),
          surface: Colors.white,
          onSurface: Color(0xFF121212),
          surfaceTint: Colors.transparent,
          surfaceContainerHighest: Color(0xFFE8E8E8),
          error: Color(0xFFB00020),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F9FA),
          foregroundColor: Color(0xFF121212),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Color(0xFF1AA34A),
        ),
      );
}
