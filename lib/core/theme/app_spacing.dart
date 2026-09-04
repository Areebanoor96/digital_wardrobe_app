import 'package:flutter/material.dart';

/// Centralised spacing scale for Digital Wardrobe.
///
/// Screens and widgets should prefer these tokens over arbitrary
/// `EdgeInsets` values to remove spacing drift and keep vertical/horizontal
/// rhythm consistent across the app.
abstract final class AppSpacing {
  /// 4px — the base unit of the scale.
  static const double xs = 4;

  /// 8px — compact gaps between related inline elements.
  static const double sm = 8;

  /// 12px — comfortable gap between related elements.
  static const double md = 12;

  /// 16px — standard gap between sections and list rows.
  static const double lg = 16;

  /// 20px — standard screen gutter and inter-card spacing.
  static const double xl = 20;

  /// 24px — spacious grouping / screen top-level padding.
  static const double xxl = 24;

  /// 32px — prominent separation between major content blocks.
  static const double xxxl = 32;

  /// 48px — generous spacing used for empty states / hero moments.
  static const double hero = 48;

  // --- Convenient EdgeInsets helpers ---

  /// Standard horizontal screen gutter (e.g. `horizontal: 20`).
  static const EdgeInsets hStandard = EdgeInsets.symmetric(
    horizontal: xl,
  );

  /// Standard vertical rhythm between blocks (e.g. `vertical: 16`).
  static const EdgeInsets vStandard = EdgeInsets.symmetric(vertical: lg);

  /// Compact screen padding (`all: 20`) matching the current default gutter.
  static const EdgeInsets allPage = EdgeInsets.all(xl);

  /// Padding used around a card's inner content.
  static const EdgeInsets cardInner = EdgeInsets.all(lg);

  /// Padding used around a dialogs / sheets content.
  static const EdgeInsets sheetInner = EdgeInsets.fromLTRB(xl, sm, xl, xl);

  /// Standard list tile content {@link EdgeInsets} used by sections.
  static const EdgeInsets listTile = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: sm,
  );
}