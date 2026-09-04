import 'package:digital_wardrobe_app/core/theme/app_radius.dart';
import 'package:digital_wardrobe_app/core/theme/app_spacing.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/wardrobe/utils/garment_metadata_formatter.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/garment_image.dart';
import 'package:flutter/material.dart';

/// Photography-first garment tile for the fashion catalog.
///
/// The garment image is the hero. Metadata underneath stays compact: name,
/// category and a single "Color - Size" line — a catalog tile, not a card
/// with buttons. The tile keeps the prior [GarmentCard] behaviour (tap,
/// optional action overlay, optional "In Closet Vault" badge, wear count).
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
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String sizeSummary = GarmentMetadataFormatter.sizeSummary(
      garment.effectiveSizes,
    );
    final List<String> metadata = <String>[
      if (garment.colorName != null) garment.colorName!,
      if (sizeSummary.isNotEmpty) sizeSummary,
    ];
    final String categoryLabel = GarmentMetadataFormatter.categoryLabel(
      garment.category,
    );

    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  GarmentImage(imageUrl: garment.coverImageUrl),
                  if (showArchivedBadge)
                    Positioned(
                      top: AppSpacing.sm,
                      left: AppSpacing.sm,
                      child: _GlassLabel(
                        text: 'In Closet Vault',
                        colors: colors,
                      ),
                    ),
                  if (onAction != null && actionIcon != null)
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: Material(
                        color: colors.surface.withValues(alpha: 0.88),
                        shape: const CircleBorder(),
                        child: IconButton(
                          onPressed: onAction,
                          icon: Icon(actionIcon),
                          tooltip: actionTooltip,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  if (garment.wearCount > 0)
                    Positioned(
                      bottom: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: _WearCountLabel(
                        count: garment.wearCount,
                        colors: colors,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, AppSpacing.sm, 0, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  garment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(height: 1.2),
                ),
                const SizedBox(height: 2),
                Text(
                  categoryLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                if (metadata.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    metadata.join(' - '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small translucent badge shown over a garment image.
class _GlassLabel extends StatelessWidget {
  const _GlassLabel({required this.text, required this.colors});

  final String text;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.78),
        borderRadius: AppRadius.stadium,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs + 1,
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.surface,
          ),
        ),
      ),
    );
  }
}

/// Quiet wear-count chip, kept subtle so the photograph stays the focus.
class _WearCountLabel extends StatelessWidget {
  const _WearCountLabel({required this.count, required this.colors});

  final int count;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.82),
        borderRadius: AppRadius.stadium,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs + 1,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.checkroom_outlined,
              size: AppSpacing.md,
              color: colors.surface,
            ),
            const SizedBox(width: AppSpacing.xs + 1),
            Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.surface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}