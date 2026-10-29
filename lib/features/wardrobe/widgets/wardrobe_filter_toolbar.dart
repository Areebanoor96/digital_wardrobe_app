import 'package:digital_wardrobe_app/core/theme/app_spacing.dart';
import 'package:digital_wardrobe_app/features/wardrobe/models/wardrobe_filters.dart';
import 'package:flutter/material.dart';

/// Compact filter + sort controls for the wardrobe catalog matching Figma.
///
/// Features two balanced pill buttons ('Sort by' and 'Filter by') with rounded
/// pill radii and solid Dark Olive Green active styling.
class WardrobeFilterToolbar extends StatelessWidget {
  const WardrobeFilterToolbar({
    super.key,
    required this.filters,
    required this.onOpenFilters,
    required this.onSortSelected,
  });

  final WardrobeFilters filters;
  final VoidCallback onOpenFilters;
  final ValueChanged<WardrobeSortOption> onSortSelected;

  @override
  Widget build(BuildContext context) {
    const Color activeColor = Color(0xFF4A5D4E);
    final bool isFiltered = filters.activeFilterCount > 0;
    final bool isSorted = filters.sortOption != WardrobeSortOption.newestAdded;

    return Row(
      children: <Widget>[
        Expanded(
          child: PopupMenuButton<WardrobeSortOption>(
            initialValue: filters.sortOption,
            tooltip: 'Sort by',
            onSelected: onSortSelected,
            itemBuilder: (BuildContext context) {
              return WardrobeSortOption.values.map(
                (WardrobeSortOption option) => PopupMenuItem<WardrobeSortOption>(
                  value: option,
                  child: Row(
                    children: <Widget>[
                      if (filters.sortOption == option) ...<Widget>[
                        const Icon(Icons.check, size: AppSpacing.lg, color: activeColor),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Expanded(
                        child: Text(
                          option.label,
                          style: TextStyle(
                            fontWeight: filters.sortOption == option
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).toList();
            },
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: isSorted ? activeColor : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSorted ? activeColor : const Color(0xFFE5E4DE),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                isSorted ? 'Sort: ${filters.sortOption.label}' : 'Sort by',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSorted ? Colors.white : const Color(0xFF636366),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: InkWell(
            onTap: onOpenFilters,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: isFiltered ? activeColor : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isFiltered ? activeColor : const Color(0xFFE5E4DE),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Filter by',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isFiltered ? Colors.white : const Color(0xFF636366),
                    ),
                  ),
                  if (isFiltered) ...<Widget>[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${filters.activeFilterCount}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: activeColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
