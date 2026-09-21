import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/outfit.dart';
import 'package:flutter/material.dart';
import 'package:digital_wardrobe_app/features/outfits/widgets/outfit_preview_grid.dart';

class OutfitCard extends StatelessWidget {
  const OutfitCard({
    super.key,
    required this.outfit,
    required this.garments,
    required this.onTap,
  });

  final Outfit outfit;
  final List<Garment> garments;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                OutfitPreviewGrid(garments: garments),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        outfit.name?.isNotEmpty == true
                            ? outfit.name!
                            : 'Untitled outfit',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${outfit.garmentIds.length} garments • Created ${_formatDate(outfit.createdAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Status Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: outfit.lastWornDate == null
                              ? theme.colorScheme.surfaceContainerHighest
                              : theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          outfit.lastWornDate == null
                              ? 'Not worn yet'
                              : 'Worn ${_formatDate(outfit.lastWornDate)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: outfit.lastWornDate == null
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) => date == null
      ? '—'
      : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}