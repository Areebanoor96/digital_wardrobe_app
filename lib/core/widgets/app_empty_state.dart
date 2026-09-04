import 'package:flutter/material.dart';

import '../theme/app_dimensions.dart';
import '../theme/app_spacing.dart';

/// Reusable empty-state / error presentation used across screens.
///
/// Replaces ad-hoc `Center(Text("..."))` blocks with a consistent language:
/// a soft hero icon, an optional title, supporting message, and an optional
/// primary action (e.g. "Retry"). This widget is purely presentational and
/// never owns retry logic — callers pass callbacks.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  /// Leading icon. When null the icon is hidden (text-only empty state).
  final IconData? icon;

  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Container(
                width: AppDimensions.avatarMd + AppSpacing.xl,
                height: AppDimensions.avatarMd + AppSpacing.xl,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: AppDimensions.iconLg * 1.6,
                  color: iconColor ?? scheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh, size: AppDimensions.iconMd),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Convenience error variant. Uses the error accent for the icon but keeps
/// the exact same [AppEmptyState] layout.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    this.icon = Icons.error_outline,
    required this.title,
    this.message,
    this.actionLabel = 'Retry',
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: icon,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      iconColor: Theme.of(context).colorScheme.error,
    );
  }
}