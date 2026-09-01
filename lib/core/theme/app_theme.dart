import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static const Color primary = Color(0xFF6C5CE7);

  static const Color lightBackground = Color(0xFFFAFAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightBorder = Color(0xFFEEEFF3);

  static const Color darkBackground = Color(0xFF12121C);
  static const Color darkSurface = Color(0xFF1C1C2B);
  static const Color darkTextPrimary = Color(0xFFF5F5F9);
  static const Color darkTextSecondary = Color(0xFFA6A8BC);
  static const Color darkBorder = Color(0xFF2A2A3A);

  static ThemeData get light => _theme(
    brightness: Brightness.light,
    background: lightBackground,
    surface: lightSurface,
    textPrimary: lightTextPrimary,
    border: lightBorder,
  );

  static ThemeData get dark => _theme(
    brightness: Brightness.dark,
    background: darkBackground,
    surface: darkSurface,
    textPrimary: darkTextPrimary,
    border: darkBorder,
  );

  static ThemeData _theme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color textPrimary,
    required Color border,
  }) {
    final ColorScheme colors = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    ).copyWith(
      primary: primary,
      surface: surface,
      onSurface: textPrimary,
      outline: border,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}