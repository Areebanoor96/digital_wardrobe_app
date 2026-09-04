import 'package:digital_wardrobe_app/core/theme/app_dimensions.dart';
import 'package:digital_wardrobe_app/core/theme/app_radius.dart';
import 'package:digital_wardrobe_app/core/theme/app_spacing.dart';
import 'package:digital_wardrobe_app/features/wardrobe/models/wardrobe_filters.dart';
import 'package:flutter/material.dart';

/// Compact filter + sort controls for the wardrobe catalog.
///
/// Filters and sort occupy a slim row instead of full-width buttons: a
/// "Filter" control with an active count badge, a "Sort" popup, and a small
/// trailing piece count. All filtering/sorting behaviour is unchanged.
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
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
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
                                if (filters.sortOption == option) ...<Widget>[
                                  const Icon(Icons.check, size: AppSpacing.lg),
                                  const SizedBox(width: AppSpacing.sm),
                                ],
                                Expanded(child: Text(option.label)),
                              ],
                            ),
                          ),
                    )
                    .toList();
              },
              child: _ToolbarControl(
                leading: const Icon(
                  Icons.sort,
                  size: AppDimensions.iconMd,
                ),
                label: 'Sort',
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onOpenFilters,
              icon: const Icon(Icons.tune, size: AppDimensions.iconMd),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('Filter'),
                  if (filters.activeFilterCount > 0) ...<Widget>[
                    const SizedBox(width: AppSpacing.xs),
                    _CountBadge(
                      count: filters.activeFilterCount,
                      colors: colors,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$filteredCount',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToolbarControl extends StatelessWidget {
  const _ToolbarControl({required this.leading, required this.label});

  final Widget? leading;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (leading != null) ...<Widget>[
              leading!,
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.arrow_drop_down,
              size: AppDimensions.iconSm,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.colors});

  final int count;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
        child: Text(
          '$count',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.primary,
          ),
        ),
      ),
    );
  }
}