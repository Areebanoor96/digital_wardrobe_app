import 'package:digital_wardrobe_app/core/theme/app_spacing.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/wardrobe/utils/garment_metadata_formatter.dart';
import 'package:flutter/material.dart';

/// Clean, tab-like category navigation for the wardrobe catalog.
///
/// Avoids pill chips. Each category is a quiet text control scrollable
/// horizontally; the selected one is emphasised with brand color and a short
/// underline, so the chosen filter is obvious without visual noise.
class WardrobeCategoryNavigation extends StatelessWidget {
  const WardrobeCategoryNavigation({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
  });

  final GarmentCategory? selectedCategory;
  final ValueChanged<GarmentCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.xxxl + 8,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.hStandard,
        children: <Widget>[
          _CategoryNavItem(
            label: 'All',
            selected: selectedCategory == null,
            onSelected: () => onSelected(null),
          ),
          ...GarmentCategory.values.map(
            (GarmentCategory category) => Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: _CategoryNavItem(
                label: GarmentMetadataFormatter.categoryLabel(category),
                selected: selectedCategory == category,
                onSelected: () => onSelected(category),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryNavItem extends StatelessWidget {
  const _CategoryNavItem({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onSelected,
      child: SizedBox(
        height: AppSpacing.xxxl + 8,
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                ),
              ),
              SizedBox(
                width: selected ? 20 : 0,
                height: 3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: selected ? colors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}