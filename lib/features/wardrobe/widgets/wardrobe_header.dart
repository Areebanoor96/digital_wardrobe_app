import 'package:digital_wardrobe_app/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Editorial wardrobe identity header.
///
/// Strong typographic hierarchy: the wardrobe name leads, with an
/// understated piece count treated as supporting information rather than a
/// dashboard metric. Optionally accepts a trailing action (e.g. an avatar).
class WardrobeHeader extends StatelessWidget {
  const WardrobeHeader({
    super.key,
    required this.title,
    required this.pieceCount,
    this.subtitle,
    this.trailing,
  });

  final String title;

  /// Secondary count line, e.g. "42 pieces".
  final int pieceCount;

  /// Optional supporting line under [title].
  final String? subtitle;

  /// Optional right-aligned widget (profile avatar, etc.).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    final Widget countLine = Text(
      _countLabel(pieceCount),
      style: textTheme.labelMedium,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.sm, 0, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: textTheme.headlineMedium?.copyWith(height: 1.1),
                ),
              ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: AppSpacing.md),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          countLine,
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(subtitle!, style: textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  String _countLabel(int count) {
    return count == 1 ? '1 piece' : '$count pieces';
  }
}