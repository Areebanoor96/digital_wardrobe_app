import 'package:flutter/material.dart';

/// Central brand + semantic color tokens for Digital Wardrobe.
///
/// These constants are consumed by [AppTheme] to seed the Material colour
/// scheme. Screens and widgets should prefer `Theme.of(context).colorScheme`
/// roles (e.g. `primary`, `surfaceContainerHighest`, `onSurfaceVariant`)
/// rather than reaching directly for these raw values.
///
/// Updated to match the Figma High-End Fashion design system (Olive & Cream).
abstract final class AppPalette {
  // --- Brand / primary ---
  /// Primary accent — a sophisticated dark olive green matching Figma.
  static const Color primary = Color(0xFF4A5D4E);

  /// Slightly deeper brand tone for gradients/emphasis.
  static const Color primaryDeep = Color(0xFF38473D);

  /// Softer brand tone for tinted secondary surfaces.
  static const Color primarySoft = Color(0xFF6E8273);

  // --- Neutral base ---
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF1C1C1E);

  // --- Light neutrals (Warm Cream aesthetic) ---
  static const Color lightBackground = Color(0xFFF8F7F2);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceMuted = Color(0xFFEFEEE9);
  static const Color lightSurfaceRaised = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1C1C1E);
  static const Color lightTextSecondary = Color(0xFF636366);
  static const Color lightTextTertiary = Color(0xFF8E8E93);
  static const Color lightBorder = Color(0xFFE5E4DE);
  static const Color lightBorderStrong = Color(0xFFD6D5CF);

  // --- Dark neutrals ---
  static const Color darkBackground = Color(0xFF12121C);
  static const Color darkSurface = Color(0xFF1C1C2B);
  static const Color darkSurfaceMuted = Color(0xFF24243A);
  static const Color darkSurfaceRaised = Color(0xFF272743);
  static const Color darkTextPrimary = Color(0xFFF5F5F9);
  static const Color darkTextSecondary = Color(0xFFA6A8BC);
  static const Color darkTextTertiary = Color(0xFF7C7E93);
  static const Color darkBorder = Color(0xFF2A2A3A);
  static const Color darkBorderStrong = Color(0xFF353548);

  // --- Semantic status ---
  static const Color success = Color(0xFF4A5D4E);
  static const Color warning = Color(0xFFE09B3D);
  static const Color error = Color(0xFFE05C5C);
  static const Color info = Color(0xFF4A88C9);
}
