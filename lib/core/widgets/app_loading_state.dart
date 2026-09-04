import 'package:flutter/material.dart';

import '../theme/app_dimensions.dart';
import '../theme/app_spacing.dart';

/// Reusable loading presentation.
///
/// Replaces bare `Center(child: CircularProgressIndicator())` with a calm,
/// branded loading treatment: an optional label paired with the global
/// progress indicator (already brand-coloured via the theme).
class AppLoadingState extends StatelessWidget {
  const AppLoadingState({
    super.key,
    this.label,
    this.icon = Icons.checkroom,
    this.showIcon = true,
  });

  /// Optional supporting text under the spinner.
  final String? label;

  /// Icon shown above the spinner when [showIcon] is true.
  final IconData icon;

  /// Set false for a minimal centered spinner (e.g. inline block loading).
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    if (!showIcon) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: AppDimensions.controlMd,
              height: AppDimensions.controlMd,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
            if (label != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              Text(label!, style: Theme.of(context).textTheme.labelMedium),
            ],
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Container(
                width: AppDimensions.avatarMd + AppSpacing.lg,
                height: AppDimensions.avatarMd + AppSpacing.lg,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
              ),
              Icon(
                icon,
                size: AppDimensions.iconLg * 1.6,
                color: scheme.primary,
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
          if (label != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xl),
            Text(label!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}