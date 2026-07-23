import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const ink = Color(0xFF101820);
  static const slate = Color(0xFF1C2834);
  static const ember = Color(0xFFE85D04);
  static const gold = Color(0xFFF4A261);
  static const mist = Color(0xFFE8EEF2);
  static const moss = Color(0xFF2A9D8F);

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ember,
        brightness: Brightness.dark,
        primary: ember,
        secondary: gold,
        surface: slate,
      ),
      scaffoldBackgroundColor: ink,
    );

    return base.copyWith(
      textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.syne(
          fontWeight: FontWeight.w800,
          fontSize: 40,
          color: mist,
          height: 1.05,
        ),
        headlineMedium: GoogleFonts.syne(
          fontWeight: FontWeight.w700,
          fontSize: 24,
          color: mist,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: mist,
        ),
        bodyLarge: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          color: mist.withValues(alpha: 0.92),
        ),
        bodyMedium: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          color: mist.withValues(alpha: 0.8),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.syne(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: mist,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ember,
          foregroundColor: ink,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: slate,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: mist.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: mist.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: gold, width: 1.4),
        ),
      ),
    );
  }
}
