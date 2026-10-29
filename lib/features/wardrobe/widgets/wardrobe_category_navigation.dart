import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/wardrobe/utils/garment_metadata_formatter.dart';
import 'package:flutter/material.dart';

/// Figma-matched horizontal pill category selector.
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
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: <Widget>[
          _CategoryChipItem(
            label: 'All',
            selected: selectedCategory == null,
            onSelected: () => onSelected(null),
          ),
          const SizedBox(width: 8),
          ...GarmentCategory.values.map(
            (GarmentCategory category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _CategoryChipItem(
                label: GarmentMetadataFormatter.categoryNavLabel(category),
                selected: selectedCategory == category,
                onSelected: () => onSelected(
                  selectedCategory == category ? null : category,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChipItem extends StatelessWidget {
  const _CategoryChipItem({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    const Color activeChipColor = Color(0xFF4A5D4E);

    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? activeChipColor : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? activeChipColor : const Color(0xFFE5E4DE),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF8E8E93),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
