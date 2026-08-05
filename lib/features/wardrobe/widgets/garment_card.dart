import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/garment_image.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/garment_status_widgets.dart';
import 'package:flutter/material.dart';

class GarmentCard extends StatelessWidget {
  const GarmentCard({
    super.key,
    required this.garment,
    required this.onTap,
    this.onAction,
    this.actionIcon,
    this.actionTooltip,
    this.showArchivedBadge = false,
  });
  final Garment garment;
  final VoidCallback onTap;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  final String? actionTooltip;
  final bool showArchivedBadge;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: Theme.of(context).colorScheme.outline),
    ),
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                GarmentImage(imageUrl: garment.coverImageUrl),
                if (showArchivedBadge)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: .9),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text('Archived'),
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: onAction != null && actionIcon != null
                      ? Material(
                          color: Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: .9),
                          shape: const CircleBorder(),
                          child: IconButton(
                            onPressed: onAction,
                            icon: Icon(actionIcon),
                            tooltip: actionTooltip,
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                      : DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withValues(alpha: .9),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(
                              '${garment.wearCount} wears',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  garment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  garment.category.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (garment.colorName != null ||
                    garment.size != null) ...<Widget>[
                  const SizedBox(height: 3),
                  Text(
                    [
                      garment.colorName,
                      garment.size,
                    ].whereType<String>().join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (garment.laundryStatus != LaundryStatus.clean) ...<Widget>[
                  const SizedBox(height: 8),
                  LaundryStatusPill(status: garment.laundryStatus),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
