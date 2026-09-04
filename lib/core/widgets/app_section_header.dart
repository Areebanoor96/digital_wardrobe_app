import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Standard section label used across screens to separate content blocks.
///
/// Centralises the recurring "uppercase-ish section title with a subtle
/// secondary tone" pattern so the typography hierarchy stays consistent.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader(
    this.title, {
    super.key,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.only(
      bottom: AppSpacing.sm,
      top: AppSpacing.xs,
    ),
  });

  final String title;

  /// Optional supporting line rendered under [title].
  final String? subtitle;

  /// Optional right-aligned widget (actions, counts, links).
  final Widget? trailing;

  /// Padding around the header block.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    final Widget leftSide = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: textTheme.titleMedium),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: 2),
          Text(subtitle!, style: textTheme.bodySmall),
        ],
      ],
    );

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(child: leftSide),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}