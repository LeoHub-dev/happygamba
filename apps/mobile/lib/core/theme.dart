import 'package:flutter/material.dart';

class AppTheme {
  static const Color bgDark = Color(0xFF0D1117);
  static const Color bgCard = Color(0xFF161B22);
  static const Color accentGreen = Color(0xFF00E676);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color accentPurple = Color(0xFF9C27B0);
  static const Color textPrimary = Color(0xFFF0F6FC);
  static const Color textMuted = Color(0xFF8B949E);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgDark,
        colorScheme: const ColorScheme.dark(
          primary: accentGreen,
          secondary: accentGold,
          surface: bgCard,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bgDark,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardTheme(
          color: bgCard,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentGreen,
            foregroundColor: bgDark,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: bgCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: textMuted),
        ),
      );
}
