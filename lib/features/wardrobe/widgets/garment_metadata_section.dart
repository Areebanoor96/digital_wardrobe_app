import 'package:digital_wardrobe_app/core/theme/app_spacing.dart';
import 'package:digital_wardrobe_app/core/widgets/app_section_header.dart';
import 'package:flutter/material.dart';

/// Grouped metadata block for the garment editorial page.
///
/// Replaces the flat "Label: value" wall with titled sections containing
/// visual values and hairline dividers — designed, not datasheet-like.
class GarmentMetadataSection extends StatelessWidget {
  const GarmentMetadataSection({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AppSectionHeader(title, trailing: trailing),
        const SizedBox(height: AppSpacing.xs),
        ...List<Widget>.generate(children.length, (int index) {
          final Widget child = children[index];
          if (index < children.length - 1) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                child,
                const Divider(height: 2, thickness: 1, indent: 0),
                const SizedBox(height: AppSpacing.lg),
              ],
            );
          }
          return child;
        }),
      ],
    );
  }
}

/// A single compact metadata row (icon-led value + optional label above).
class GarmentInfoRow extends StatelessWidget {
  const GarmentInfoRow({
    super.key,
    this.label,
    required this.value,
    this.icon,
    this.trailing,
  });

  /// Optional emphasis label rendered above [value].
  final String? label;

  final String value;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    final Widget valueText = Text(
      value,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: colors.onSurface,
        height: 1.35,
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, size: 20, color: colors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: label == null
              ? valueText
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(label!, style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 2),
                    valueText,
                  ],
                ),
        ),
        if (trailing != null) ...<Widget>[
          const SizedBox(width: AppSpacing.sm),
          trailing!,
        ],
      ],
    );
  }
}