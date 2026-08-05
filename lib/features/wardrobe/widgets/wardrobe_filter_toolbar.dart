import 'package:digital_wardrobe_app/features/wardrobe/models/wardrobe_filters.dart';
import 'package:flutter/material.dart';

class WardrobeFilterToolbar extends StatelessWidget {
  const WardrobeFilterToolbar({
    super.key,
    required this.filters,
    required this.filteredCount,
    required this.totalCount,
    required this.onOpenFilters,
    required this.onSortSelected,
  });

  final WardrobeFilters filters;
  final int filteredCount;
  final int totalCount;
  final VoidCallback onOpenFilters;
  final ValueChanged<WardrobeSortOption> onSortSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: onOpenFilters,
                icon: const Icon(Icons.tune),
                label: Text(
                  filters.activeFilterCount == 0
                      ? 'Filters'
                      : 'Filters (${filters.activeFilterCount})',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PopupMenuButton<WardrobeSortOption>(
                  initialValue: filters.sortOption,
                  tooltip: 'Sort garments',
                  onSelected: onSortSelected,
                  itemBuilder: (BuildContext context) {
                    return WardrobeSortOption.values
                        .map(
                          (WardrobeSortOption option) =>
                              PopupMenuItem<WardrobeSortOption>(
                                value: option,
                                child: Row(
                                  children: <Widget>[
                                    if (filters.sortOption ==
                                        option) ...<Widget>[
                                      const Icon(Icons.check, size: 18),
                                      const SizedBox(width: 8),
                                    ],
                                    Expanded(child: Text(option.label)),
                                  ],
                                ),
                              ),
                        )
                        .toList();
                  },
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Chip(
                      avatar: const Icon(Icons.sort, size: 18),
                      label: Text(filters.sortOption.label),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$filteredCount of $totalCount garments',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
