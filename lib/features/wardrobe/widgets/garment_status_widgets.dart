import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:flutter/material.dart';

class LaundryStatusPill extends StatelessWidget {
  const LaundryStatusPill({super.key, required this.status});
  final LaundryStatus status;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final ({Color background, Color foreground, IconData icon}) style =
        switch (status) {
          LaundryStatus.clean => (
            background: colors.secondaryContainer,
            foreground: colors.onSecondaryContainer,
            icon: Icons.check_circle_outline,
          ),
          LaundryStatus.dirty => (
            background: colors.tertiaryContainer,
            foreground: colors.onTertiaryContainer,
            icon: Icons.local_laundry_service_outlined,
          ),
          LaundryStatus.washing || LaundryStatus.ironing => (
            background: colors.primaryContainer,
            foreground: colors.onPrimaryContainer,
            icon: Icons.water_drop_outlined,
          ),
        };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(style.icon, size: 15, color: style.foreground),
            const SizedBox(width: 5),
            Text(
              status.label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: style.foreground),
            ),
          ],
        ),
      ),
    );
  }
}

class WearStatsRow extends StatelessWidget {
  const WearStatsRow({super.key, required this.garment});
  final Garment garment;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: _WearStat(label: 'Times worn', value: '${garment.wearCount}'),
      ),
      Expanded(
        child: _WearStat(
          label: 'Last worn',
          value: garment.lastWornDate == null
              ? 'Not yet'
              : _shortDate(garment.lastWornDate!),
        ),
      ),
      Expanded(
        child: _WearStat(
          label: 'Cost per wear',
          value: garment.costPerWear == null
              ? '—'
              : '${garment.currency} ${garment.costPerWear!.toStringAsFixed(0)}',
        ),
      ),
    ],
  );

  String _shortDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _WearStat extends StatelessWidget {
  const _WearStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(label, style: Theme.of(context).textTheme.labelSmall),
      const SizedBox(height: 5),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    ],
  );
}
