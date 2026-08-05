import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/wardrobe/models/wardrobe_filters.dart';
import 'package:flutter/material.dart';

class ActiveFilterChips extends StatelessWidget {
  const ActiveFilterChips({
    super.key,
    required this.filters,
    required this.onColorRemoved,
    required this.onBrandRemoved,
    required this.onSizeRemoved,
    required this.onOccasionRemoved,
    required this.onSeasonRemoved,
    required this.onMoodRemoved,
    required this.onLaundryStatusRemoved,
  });

  final WardrobeFilters filters;
  final VoidCallback onColorRemoved;
  final VoidCallback onBrandRemoved;
  final VoidCallback onSizeRemoved;
  final VoidCallback onOccasionRemoved;
  final VoidCallback onSeasonRemoved;
  final VoidCallback onMoodRemoved;
  final VoidCallback onLaundryStatusRemoved;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: <Widget>[
          if (filters.color != null)
            _ActiveFilterChip(
              label: 'Color: ${filters.color}',
              onDeleted: onColorRemoved,
            ),
          if (filters.brand != null)
            _ActiveFilterChip(
              label: 'Brand: ${filters.brand}',
              onDeleted: onBrandRemoved,
            ),
          if (filters.size != null)
            _ActiveFilterChip(
              label: 'Size: ${filters.size}',
              onDeleted: onSizeRemoved,
            ),
          if (filters.occasion != null)
            _ActiveFilterChip(
              label: 'Occasion: ${filters.occasion}',
              onDeleted: onOccasionRemoved,
            ),
          if (filters.season != null)
            _ActiveFilterChip(
              label: 'Season: ${filters.season}',
              onDeleted: onSeasonRemoved,
            ),
          if (filters.mood != null)
            _ActiveFilterChip(
              label: 'Mood: ${filters.mood}',
              onDeleted: onMoodRemoved,
            ),
          if (filters.laundryStatus != null)
            _ActiveFilterChip(
              label: filters.laundryStatus!.label,
              onDeleted: onLaundryStatusRemoved,
            ),
        ],
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.label, required this.onDeleted});

  final String label;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InputChip(label: Text(label), onDeleted: onDeleted),
    );
  }
}
