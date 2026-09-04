import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Branded dialog shell for Digital Wardrobe.
///
/// Wraps [AlertDialog] (and normalises its background/shape to the global
/// `DialogTheme` so it inherits rounded corners + outline). It is purely
/// presentational — callers own the buttons, actions and dismissal behaviour.
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.icon,
    this.iconColor,
    this.scrollable = false,
  });

  final Widget? title;
  final Widget? content;

  /// Action row widgets (e.g. [TextButton] / [FilledButton]).
  final List<Widget>? actions;

  /// Optional leading icon rendered above [title].
  final IconData? icon;
  final Color? iconColor;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      scrollable: scrollable,
      iconPadding: const EdgeInsets.only(top: AppSpacing.xs),
      title: title == null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: (iconColor ?? scheme.primary).withValues(
                        alpha: 0.12,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      icon,
                      size: AppSpacing.xl,
                      color: iconColor ?? scheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(child: title!),
              ],
            ),
      content: content,
      actions: actions,
    );
  }
}

/// Helper to show a branded [AppDialog] with the standard issued action layout.
///
/// Keeps the common case compact; callers pass [title]/[message] plus
/// [confirmLabel]/[onConfirm] and an optional [cancelLabel] to mirror the
/// app's standard confirm/cancel pairing.
Future<bool> showAppDialog(
  BuildContext context, {
  required String title,
  String? message,
  IconData? icon,
  Color? iconColor,
  String confirmLabel = 'Done',
  VoidCallback? onConfirm,
  String? cancelLabel = 'Cancel',
  VoidCallback? onCancel,
  bool destructive = false,
}) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      final ColorScheme scheme = Theme.of(context).colorScheme;
      return AppDialog(
        icon: icon,
        iconColor: iconColor,
        title: Text(title),
        content: message == null ? null : Text(message),
        actions: <Widget>[
          if (cancelLabel != null)
            TextButton(
              onPressed: () {
                onCancel?.call();
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(cancelLabel),
            ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: scheme.error)
                : null,
            onPressed: () {
              onConfirm?.call();
              Navigator.of(dialogContext).pop(true);
            },
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );

  return confirmed ?? false;
}