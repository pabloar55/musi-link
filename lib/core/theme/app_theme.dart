import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1DB954),
          onPrimary: Colors.black,
          secondary: Color(0xFF1ED760),
          onSecondary: Colors.black,
          surface: Color(0xFF121212),
          onSurface: Colors.white,
          surfaceTint: Colors.transparent,
          surfaceContainerHighest: Color(0xFF2A2A2A),
          error: Color(0xFFCF6679),
          onError: Colors.black,
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
          elevation: 0,
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF181818),
          indicatorColor: Color(0xFF1DB954),
        ),
      );

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1AA34A),
          onPrimary: Colors.white,
          secondary: Color(0xFF1DB954),
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: Color(0xFF121212),
          surfaceTint: Colors.transparent,
          surfaceContainerHighest: Color(0xFFE8E8E8),
          error: Color(0xFFB00020),
          onError: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F9FA),
          foregroundColor: Color(0xFF121212),
          elevation: 0,
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFFF8F9FA),
          indicatorColor: Color(0xFF1AA34A),
        ),
      );
}
