import 'package:digital_wardrobe_app/core/theme/app_dimensions.dart';
import 'package:digital_wardrobe_app/core/theme/app_palette.dart';
import 'package:digital_wardrobe_app/core/theme/app_radius.dart';
import 'package:digital_wardrobe_app/core/theme/app_spacing.dart';
import 'package:digital_wardrobe_app/core/widgets/app_card.dart';
import 'package:digital_wardrobe_app/data/models/alert.dart';
import 'package:flutter/material.dart';

class AlertCard extends StatelessWidget {
  const AlertCard({super.key, required this.alert, this.onTap, this.onDismiss});

  final Alert alert;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool unread = !alert.isRead;
    final String body = alert.body ?? '';

    return AppCard(
      padding: EdgeInsets.zero,
      color: unread ? colors.primaryContainer.withValues(alpha: 0.38) : null,
      border: unread
          ? Border.all(color: colors.primary.withValues(alpha: 0.35))
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _AlertIcon(type: alert.type, isRead: alert.isRead),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            alert.title,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: unread ? colors.primary : colors.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        IconButton(
                          onPressed: onDismiss,
                          iconSize: AppDimensions.iconSm,
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Dismiss',
                          icon: Icon(
                            Icons.close,
                            color: colors.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                    if (body.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      Text(body, style: textTheme.bodySmall),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _formatDate(alert.createdAt),
                      style: textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final DateTime now = DateTime.now();
    final Duration diff = now.difference(date);
    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _AlertIcon extends StatelessWidget {
  const _AlertIcon({required this.type, required this.isRead});

  final AlertType type;
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color accent = isRead
        ? colors.onSurface.withValues(alpha: 0.35)
        : _accentColor(colors, type);

    return Container(
      width: AppDimensions.touchTarget,
      height: AppDimensions.touchTarget,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isRead ? 0.08 : 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(_iconData, size: AppDimensions.iconLg, color: accent),
    );
  }

  IconData get _iconData => switch (type) {
    AlertType.unused => Icons.watch_later_outlined,
    AlertType.laundry => Icons.local_laundry_service_outlined,
    AlertType.ootd => Icons.auto_awesome_outlined,
    AlertType.growth => Icons.trending_up,
    AlertType.lendReturn => Icons.swap_horiz,
    AlertType.handMeDown => Icons.child_care_outlined,
    AlertType.expiry => Icons.info_outline,
    AlertType.sale => Icons.local_offer_outlined,
  };

  Color _accentColor(ColorScheme colors, AlertType type) => switch (type) {
    AlertType.unused => AppPalette.warning,
    AlertType.laundry => AppPalette.info,
    AlertType.ootd => colors.primary,
    AlertType.growth => AppPalette.success,
    AlertType.lendReturn => colors.secondary,
    AlertType.handMeDown => AppPalette.success,
    AlertType.expiry => colors.error,
    AlertType.sale => AppPalette.warning,
  };
}