import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:flutter/material.dart';

class WardrobeCategoryChips extends StatelessWidget {
  const WardrobeCategoryChips({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
  });

  final GarmentCategory? selectedCategory;
  final ValueChanged<GarmentCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: <Widget>[
          ChoiceChip(
            label: const Text('All'),
            selected: selectedCategory == null,
            onSelected: (_) => onSelected(null),
          ),
          ...GarmentCategory.values.map(
            (GarmentCategory category) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ChoiceChip(
                label: Text(category.label),
                selected: selectedCategory == category,
                onSelected: (_) => onSelected(category),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
