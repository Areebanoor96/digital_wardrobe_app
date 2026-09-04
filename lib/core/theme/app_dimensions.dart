/// Centralised component metrics for Digital Wardrobe.
///
/// Standardised heights keep buttons, chips, list rows and touch targets
/// harmonious without every control inventing its own size.
abstract final class AppDimensions {
  // --- Standard interactive heights ---

  /// Primary / large action button height.
  static const double controlLg = 52;

  /// Secondary / default control height.
  static const double controlMd = 44;

  /// Compact control height (chips, small buttons).
  static const double controlSm = 36;

  /// Minimum touch-target height for list rows.
  static const double touchTarget = 48;

  // --- Icon sizing ---

  /// Small inline icon (list leading, lightweight actions).
  static const double iconSm = 16;

  /// Default action icon.
  static const double iconMd = 20;

  /// Prominent icon (empty-state hero, feature highlight).
  static const double iconLg = 24;

  /// Hero icon used by empty/error states.
  static const double iconHero = 64;

  // --- Avatar ---
  static const double avatarSm = 40;
  static const double avatarMd = 72;
  static const double avatarLg = 96;
}