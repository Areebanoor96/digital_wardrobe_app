import 'package:flutter/material.dart';

/// Centralised corner-radius tokens for Digital Wardrobe.
///
/// Using a small intentional radius scale instead of scattered
/// `BorderRadius.circular(16/18/20/24)` values keeps the surface language
/// consistent and gives cards, buttons and inputs a cohesive silhouette.
abstract final class AppRadius {
  /// 6px — small controls, tags-in-a-row, checkbox rounding.
  static const double xs = 6;

  /// 12px — text fields, thumbnails, tight chips.
  static const double sm = 12;

  /// 16px — standard panels, secondary cards, media thumbnails.
  static const double md = 16;

  /// 20px — the primary card radius (elevation-0 outlined cards).
  static const double lg = 20;

  /// 24px — large hero containers / feature cards.
  static const double xl = 24;

  /// 28px — fully-pill shape for stadium elements.
  static const double pill = 28;

  // --- Ready-made BorderRadius / BorderRadiusGeometry helpers ---

  /// Primary card corner shape.
  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));

  /// Standard panel / container corner shape.
  static const BorderRadius panel = BorderRadius.all(Radius.circular(md));

  /// Input-field corner shape.
  static const BorderRadius input = BorderRadius.all(Radius.circular(sm));

  /// Fully rounded stadium shape (use sparingly).
  static const BorderRadius stadium = BorderRadius.all(Radius.circular(pill));
}