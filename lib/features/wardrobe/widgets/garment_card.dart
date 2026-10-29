import 'package:digital_wardrobe_app/core/theme/app_radius.dart';
import 'package:digital_wardrobe_app/core/theme/app_spacing.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/wardrobe/utils/garment_metadata_formatter.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/garment_image.dart';
import 'package:flutter/material.dart';

/// Designer-matched Garment Card featuring rounded 20px corners, neat image
/// scaling, and subtle heart favorite icon placed neatly inside the card layout.
class GarmentCard extends StatelessWidget {
  const GarmentCard({
    super.key,
    required this.garment,
    required this.onTap,
    this.onAction,
    this.actionIcon,
    this.actionTooltip,
    this.showArchivedBadge = false,
    this.isFavorite = false,
    this.onToggleFavorite,
    this.showMetadata = true,
  });

  final Garment garment;
  final VoidCallback onTap;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  final String? actionTooltip;
  final bool showArchivedBadge;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;
  final bool showMetadata;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    final Widget imageContent = Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: GarmentImage(
            imageUrl: garment.coverImageUrl,
            fit: BoxFit.cover,
          ),
        ),
        if (showArchivedBadge)
          Positioned(
            top: 10,
            left: 10,
            child: _GlassLabel(
              text: 'In Closet Vault',
              colors: colors,
            ),
          ),
        if (onToggleFavorite != null)
          Positioned(
            top: 10,
            right: 10,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 1,
              shadowColor: Colors.black26,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onToggleFavorite,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border_rounded,
                    size: 18,
                    color: isFavorite
                        ? const Color(0xFF4A5D4E)
                        : const Color(0xFF1C1C1E),
                  ),
                ),
              ),
            ),
          )
        else if (onAction != null && actionIcon != null)
          Positioned(
            top: 10,
            right: 10,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 1,
              shadowColor: Colors.black26,
              child: IconButton(
                onPressed: onAction,
                icon: Icon(actionIcon, size: 18, color: const Color(0xFF1C1C1E)),
                tooltip: actionTooltip,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        if (garment.wearCount > 0)
          Positioned(
            bottom: 10,
            left: 10,
            child: _WearCountLabel(
              count: garment.wearCount,
              colors: colors,
            ),
          ),
      ],
    );

    if (!showMetadata) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: imageContent,
      );
    }

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
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 1,
            child: imageContent,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, AppSpacing.sm, 4, 10),
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
        color: Colors.black.withValues(alpha: 0.65),
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
            color: Colors.white,
            fontSize: 10,
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
        color: Colors.black.withValues(alpha: 0.65),
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
            const Icon(
              Icons.checkroom_outlined,
              size: 12,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
