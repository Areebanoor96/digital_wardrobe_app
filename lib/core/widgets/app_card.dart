import 'package:flutter/material.dart';

import '../theme/app_radius.dart';

/// The single reusable card surface for Digital Wardrobe.
///
/// Wraps [Card] so every card in the app shares the same primary card
/// language: elevation 0, a subtle outline, and a consistent radius — no
/// default Material drop shadows unless [elevation] is explicitly overridden.
///
/// Screens should prefer [AppCard] over raw [Card] to keep the surface
/// language coherent. Alternatively, use plain [Card] and it will inherit the
/// global `CardTheme` (same outline + radius) automatically.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.color,
    this.elevation = 0,
    this.radius = AppRadius.lg,
    this.border,
    this.shape,
    this.margin,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;

  /// When provided the card becomes tappable (wraps the surface in [InkWell]).
  final VoidCallback? onTap;

  /// Inner padding around [child]. Defaults to a neutral, comfortable inset.
  final EdgeInsetsGeometry? padding;

  /// Background color. Defaults to the theme surface.
  final Color? color;

  /// Elevation. Defaults to 0 (no shadow) per the app language.
  final double elevation;

  /// Corner radius. Defaults to the primary card radius token.
  final double radius;

  /// Optional [Border] for [shape]. Overrides radius if provided.
  final Border? border;

  /// Full [ShapeBorder]. When null a rounded rectangle from [radius]/[border]
  /// is used.
  final ShapeBorder? shape;

  final EdgeInsetsGeometry? margin;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color borderColor = border?.top.color ??
        Theme.of(context).colorScheme.outlineVariant;

    final ShapeBorder resolvedShape = shape ??
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: borderColor),
        );

    final Widget surface = Card(
      elevation: elevation,
      margin: margin,
      color: color ?? scheme.surface,
      surfaceTintColor: elevation == 0 ? Colors.transparent : null,
      shadowColor: elevation == 0 ? Colors.transparent : null,
      shape: resolvedShape,
      clipBehavior: clipBehavior,
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      ),
    );

    if (onTap == null) {
      return surface;
    }

    return InkWell(onTap: onTap, child: surface);
  }
}