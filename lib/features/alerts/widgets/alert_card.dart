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
              const _AlertIcon(),
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
  const _AlertIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppDimensions.touchTarget,
      height: AppDimensions.touchTarget,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // Soft Green Highlight Circle Badge
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: Color(0xFFDCE8CF),
              shape: BoxShape.circle,
            ),
          ),
          // Hanger Icon
          const Icon(
            Icons.checkroom_outlined,
            size: 22,
            color: Color(0xFF1C1C1E),
          ),
        ],
      ),
    );
  }
}