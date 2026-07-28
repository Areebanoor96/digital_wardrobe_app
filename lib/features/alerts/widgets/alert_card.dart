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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: alert.isRead
              ? colors.outline
              : colors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _AlertIcon(type: alert.type, isRead: alert.isRead),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            alert.title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: alert.isRead
                                      ? colors.onSurface
                                      : colors.primary,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: onDismiss,
                          iconSize: 18,
                          icon: Icon(
                            Icons.close,
                            color: colors.onSurface.withValues(alpha: 0.4),
                          ),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Dismiss',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.body ?? '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(alert.createdAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.4),
                      ),
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
    final Color iconColor = isRead
        ? colors.onSurface.withValues(alpha: 0.5)
        : _iconColor(colors);

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(_iconData, size: 22, color: iconColor),
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

  Color _iconColor(ColorScheme colors) => switch (type) {
    AlertType.unused => Colors.orange,
    AlertType.laundry => Colors.blue,
    AlertType.ootd => colors.primary,
    AlertType.growth => Colors.green,
    AlertType.lendReturn => Colors.purple,
    AlertType.handMeDown => Colors.teal,
    AlertType.expiry => Colors.red,
    AlertType.sale => Colors.amber,
  };
}
