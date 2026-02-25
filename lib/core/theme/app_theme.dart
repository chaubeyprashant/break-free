import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Premium palette: deep teal, mint accent, warm surface
  static const Color primaryDark = Color(0xFF1A535C);
  static const Color primary = Color(0xFF2A9D8F);
  static const Color accent = Color(0xFF4ECDC4);
  static const Color surfaceLight = Color(0xFFF7FFF7);
  static const Color surfaceDark = Color(0xFF0D1117);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF161B22);

  static final lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: accent,
      surface: surfaceLight,
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.outfitTextTheme().copyWith(
      headlineLarge: GoogleFonts.outfit(fontWeight: FontWeight.w800, letterSpacing: -0.5),
      headlineMedium: GoogleFonts.outfit(fontWeight: FontWeight.w700),
      titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w700),
      titleMedium: GoogleFonts.outfit(fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.outfit(height: 1.4),
    ),
    scaffoldBackgroundColor: surfaceLight,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: primaryDark,
      titleTextStyle: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: cardLight,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: accent,
      secondary: accent,
      surface: surfaceDark,
      brightness: Brightness.dark,
    ),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
      headlineLarge: GoogleFonts.outfit(fontWeight: FontWeight.w800, letterSpacing: -0.5),
      headlineMedium: GoogleFonts.outfit(fontWeight: FontWeight.w700),
      titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w700),
      titleMedium: GoogleFonts.outfit(fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.outfit(height: 1.4),
    ),
    scaffoldBackgroundColor: surfaceDark,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      titleTextStyle: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: cardDark,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
  );
}
