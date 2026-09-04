import 'package:digital_wardrobe_app/core/theme/app_spacing.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:flutter/material.dart';

/// Editorial wear insight for a garment.
///
/// Two quiet metrics — total wears and last worn — rendered below the garment
/// title, treated as wardrobe intelligence rather than a dashboard statistic.
class GarmentWearInsight extends StatelessWidget {
  const GarmentWearInsight({super.key, required this.garment});

  final Garment garment;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Row(
      children: <Widget>[
        _Metric(
          icon: Icons.checkroom_outlined,
          value: '${garment.wearCount}',
          label: garment.wearCount == 1 ? 'wear' : 'wears',
          colors: colors,
        ),
        const SizedBox(width: AppSpacing.xl),
        _Metric(
          icon: Icons.history_outlined,
          value: garment.lastWornDate == null
              ? 'Not yet'
              : _shortDate(garment.lastWornDate!),
          label: 'last worn',
          colors: colors,
        ),
      ],
    );
  }

  String _shortDate(DateTime date) {
    const List<String> months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.value,
    required this.label,
    required this.colors,
  });

  final IconData icon;
  final String value;
  final String label;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 20, color: colors.primary),
        const SizedBox(width: AppSpacing.xs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ],
    );
  }
}