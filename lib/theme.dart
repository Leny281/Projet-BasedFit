import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF2563EB); // Bleu pro
  static const Color accent = Color(0xFF60A5FA); // Bleu clair
  static const Color background = Color(0xFFF5F6FA); // Blanc cassé
  static const Color surface = Color(0xFFFFFFFF);
  static const Color darkBackground = Color(0xFF181A20);
  static const Color darkSurface = Color(0xFF23262F);
  static const Color text = Color(0xFF222B45);
  static const Color textLight = Color(0xFF8F9BB3);

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primary,
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    colorScheme: ColorScheme.light(
      primary: primary,
      secondary: accent,
      background: background,
      surface: surface,
      onPrimary: Colors.white,
      onSurface: text,
    ),
    cardColor: surface,
    iconTheme: const IconThemeData(color: primary),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: text, fontSize: 16),
      bodyMedium: TextStyle(color: text, fontSize: 14),
      titleLarge: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 20),
      titleMedium: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 16),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: accent.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      labelStyle: const TextStyle(color: textLight),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        elevation: 2,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: primary,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primary,
      unselectedItemColor: textLight,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primary,
    scaffoldBackgroundColor: darkBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    colorScheme: ColorScheme.dark(
      primary: primary,
      secondary: accent,
      background: darkBackground,
      surface: darkSurface,
      onPrimary: Colors.white,
      onSurface: Colors.white,
    ),
    cardColor: darkSurface,
    iconTheme: const IconThemeData(color: accent),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
      bodyMedium: TextStyle(color: Colors.white, fontSize: 14),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
      titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: accent.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: accent, width: 2),
      ),
      labelStyle: const TextStyle(color: Colors.white70),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        elevation: 2,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: accent,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: accent,
      unselectedItemColor: Colors.white54,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
    ),
  );
}
