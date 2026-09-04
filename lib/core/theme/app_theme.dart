import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_dimensions.dart';
import 'app_palette.dart';
import 'app_radius.dart';
import 'app_spacing.dart';

/// Central application theme for Digital Wardrobe — the "Modern Fashion OS".
///
/// This file is the single source of truth for the Material visual language.
/// Screens should inherit styling from these themes rather than inventing
/// their own colours, radii, shadows or button styles. This keeps the app
/// looking coherent and removes styling drift between screens.
///
/// The lavender/purple brand identity ([AppPalette.primary]) is preserved and
/// used intentionally — as an accent and for primary actions — rather than
/// covering the whole interface in purple.
abstract final class AppTheme {
  static const Color primary = AppPalette.primary;

  static ThemeData get light => _build(ThemeModeLightPalette(), Brightness.light);

  static ThemeData get dark => _build(ThemeModeDarkPalette(), Brightness.dark);
}

/// Holds the light/dark neutral + semantic colors so both modes share the
/// exact same Material configuration.
class ThemeModeLightPalette with Palette {
  @override
  Color get background => AppPalette.lightBackground;
  @override
  Color get surface => AppPalette.lightSurface;
  @override
  Color get surfaceMuted => AppPalette.lightSurfaceMuted;
  @override
  Color get surfaceRaised => AppPalette.lightSurfaceRaised;
  @override
  Color get textPrimary => AppPalette.lightTextPrimary;
  @override
  Color get textSecondary => AppPalette.lightTextSecondary;
  @override
  Color get textTertiary => AppPalette.lightTextTertiary;
  @override
  Color get border => AppPalette.lightBorder;
  @override
  Color get borderStrong => AppPalette.lightBorderStrong;
}

class ThemeModeDarkPalette with Palette {
  @override
  Color get background => AppPalette.darkBackground;
  @override
  Color get surface => AppPalette.darkSurface;
  @override
  Color get surfaceMuted => AppPalette.darkSurfaceMuted;
  @override
  Color get surfaceRaised => AppPalette.darkSurfaceRaised;
  @override
  Color get textPrimary => AppPalette.darkTextPrimary;
  @override
  Color get textSecondary => AppPalette.darkTextSecondary;
  @override
  Color get textTertiary => AppPalette.darkTextTertiary;
  @override
  Color get border => AppPalette.darkBorder;
  @override
  Color get borderStrong => AppPalette.darkBorderStrong;
}

ThemeData _build(Palette p, Brightness brightness) {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: AppPalette.primary,
    brightness: brightness,
  ).copyWith(
    primary: AppPalette.primary,
    // Refine primary container to a softer lavender tint.
    primaryContainer: brightness == Brightness.light
        ? const Color(0xFFEDEAFD)
        : const Color(0xFF322A63),
    onPrimaryContainer: brightness == Brightness.light
        ? const Color(0xFF241D52)
        : const Color(0xFFE7E3F9),
    surface: p.surface,
    onSurface: p.textPrimary,
    onSurfaceVariant: p.textSecondary,
    outline: p.border,
    outlineVariant: p.borderStrong,
    surfaceContainerLowest: p.surface,
    surfaceContainerLow: p.surfaceMuted,
    surfaceContainer: p.surfaceMuted,
    surfaceContainerHigh: brightness == Brightness.light
        ? const Color(0xFFEFEFF4)
        : const Color(0xFF292940),
    surfaceContainerHighest: brightness == Brightness.light
        ? const Color(0xFFECECF2)
        : const Color(0xFF2E2E47),
    error: AppPalette.error,
    tertiary: AppPalette.success,
  );

  final TextTheme textTheme = GoogleFonts.plusJakartaSansTextTheme().apply(
    bodyColor: p.textPrimary,
    displayColor: p.textPrimary,
  );

  final ThemeData base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.background,
    textTheme: textTheme,
  );

  return base.copyWith(
    // --- Typography: editorial, restrained scale ---
    textTheme: textTheme.copyWith(
      displaySmall: textTheme.displaySmall?.copyWith(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineLarge: textTheme.headlineLarge?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      headlineMedium: textTheme.headlineMedium?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      headlineSmall: textTheme.headlineSmall?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: textTheme.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      titleSmall: textTheme.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: textTheme.bodyLarge?.copyWith(fontSize: 16),
      bodyMedium: textTheme.bodyMedium?.copyWith(fontSize: 14, height: 1.4),
      bodySmall: textTheme.bodySmall?.copyWith(
        fontSize: 13,
        color: p.textSecondary,
      ),
      labelLarge: textTheme.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      labelMedium: textTheme.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: p.textSecondary,
      ),
      labelSmall: textTheme.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: p.textTertiary,
        letterSpacing: 0.3,
      ),
    ),

    // --- AppBar: clean, understated, surface-grounded ---
    appBarTheme: AppBarTheme(
      backgroundColor: p.background,
      foregroundColor: p.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: p.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      surfaceTintColor: Colors.transparent,
    ),

    // --- Cards: ONE primary card language ---
    // elevation 0 + subtle outline + consistent 20px radius, no default
    // drop shadows unless explicitly requested per instance.
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: p.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.card,
        side: BorderSide(color: p.border),
      ),
    ),

    // --- Inputs: filled, calm, preferred radius ---
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surfaceMuted,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      hintStyle: textTheme.bodyMedium?.copyWith(color: p.textTertiary),
      labelStyle: textTheme.bodyMedium?.copyWith(color: p.textSecondary),
      floatingLabelStyle: textTheme.bodyMedium?.copyWith(
        color: AppPalette.primary,
      ),
      border: OutlineInputBorder(
        borderRadius: AppRadius.input,
        borderSide: BorderSide(color: p.borderStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.input,
        borderSide: BorderSide(color: p.borderStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.input,
        borderSide: const BorderSide(color: AppPalette.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.input,
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.input,
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      ),
      prefixIconColor: p.textSecondary,
      suffixIconColor: p.textSecondary,
    ),

    // --- Buttons: confident primary, quieter secondary ---
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, AppDimensions.controlMd),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.sm,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, AppDimensions.controlMd),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        side: BorderSide(color: p.borderStrong),
        foregroundColor: p.textPrimary,
        textStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.sm,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, AppDimensions.controlSm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        foregroundColor: AppPalette.primary,
        textStyle: textTheme.labelLarge,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: p.surface,
        foregroundColor: p.textPrimary,
        minimumSize: const Size(0, AppDimensions.controlMd),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        side: BorderSide(color: p.borderStrong),
        textStyle: textTheme.labelLarge,
      ),
    ),

    // --- FAB: subtle, keyed to the appbar surface ---
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppPalette.primary,
      foregroundColor: AppPalette.white,
      elevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),

    // --- Chips: restrained, less pill-heavy ---
    chipTheme: ChipThemeData(
      backgroundColor: p.surfaceMuted,
      selectedColor: scheme.primaryContainer,
      disabledColor: p.surfaceMuted.withValues(alpha: 0.5),
      secondarySelectedColor: scheme.primaryContainer,
      side: BorderSide(color: p.borderStrong),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      labelStyle: textTheme.labelMedium?.copyWith(color: p.textPrimary),
      secondaryLabelStyle: textTheme.labelMedium?.copyWith(
        color: AppPalette.primary,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      iconTheme: IconThemeData(color: p.textSecondary, size: AppDimensions.iconSm),
      checkmarkColor: AppPalette.primary,
    ),

    // --- Dialogs / sheets: part of Digital Wardrobe, not stock Flutter ---
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(color: p.border),
      ),
      titleTextStyle: textTheme.titleLarge?.copyWith(color: p.textPrimary),
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: p.textSecondary),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      showDragHandle: true,
      dragHandleColor: p.borderStrong,
    ),

    // --- Dividers: subtle, understated ---
    dividerTheme: DividerThemeData(
      color: p.border,
      thickness: 1,
      space: AppSpacing.sm,
    ),

    // --- Navigation bar: modern fashion, clean + understated ---
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: AppDimensions.controlLg + AppSpacing.lg,
      indicatorColor: scheme.primaryContainer,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (Set<WidgetState> states) => textTheme.labelSmall?.copyWith(
          color: states.contains(WidgetState.selected)
              ? AppPalette.primary
              : p.textTertiary,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w600,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (Set<WidgetState> states) => IconThemeData(
          size: AppDimensions.iconMd,
          color: states.contains(WidgetState.selected)
              ? AppPalette.primary
              : p.textSecondary,
        ),
      ),
    ),

    // --- List tiles: calm rows ---
    listTileTheme: ListTileThemeData(
      iconColor: p.textSecondary,
      textColor: p.textPrimary,
      contentPadding: AppSpacing.listTile,
    ),

    // --- Snack/bottom: neutral feedback bars ---
    snackBarTheme: SnackBarThemeData(
      backgroundColor: brightness == Brightness.light
          ? const Color(0xFF2B2B3A)
          : const Color(0xFFE9E9F0),
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),

    // --- Dropdown / menus: consistent surface ---
    popupMenuTheme: PopupMenuThemeData(
      color: p.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: p.border),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: base.inputDecorationTheme,
      textStyle: textTheme.bodyMedium?.copyWith(color: p.textPrimary),
    ),

    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: AppPalette.primary,
      linearTrackColor: p.surfaceMuted,
      circularTrackColor: p.surfaceMuted,
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (Set<WidgetState> states) => states.contains(WidgetState.selected)
            ? AppPalette.primary
            : p.textTertiary,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (Set<WidgetState> states) => states.contains(WidgetState.selected)
            ? scheme.primaryContainer
            : p.surfaceMuted,
      ),
    ),
  );
}

/// Private helper describing just the neutral colors shared between modes so
/// the build method stays readable.
mixin Palette {
  Color get background;
  Color get surface;
  Color get surfaceMuted;
  Color get surfaceRaised;
  Color get textPrimary;
  Color get textSecondary;
  Color get textTertiary;
  Color get border;
  Color get borderStrong;
}