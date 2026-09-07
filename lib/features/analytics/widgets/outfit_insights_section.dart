import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/core/theme/app_radius.dart';
import 'package:digital_wardrobe_app/core/theme/app_spacing.dart';
import 'package:digital_wardrobe_app/core/widgets/app_card.dart';
import 'package:digital_wardrobe_app/core/widgets/app_empty_state.dart';
import 'package:digital_wardrobe_app/core/widgets/app_loading_state.dart';
import 'package:digital_wardrobe_app/core/widgets/app_section_header.dart';
import 'package:digital_wardrobe_app/data/models/outfit.dart';
import 'package:digital_wardrobe_app/features/analytics/widgets/wear_activity_section.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/garment_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Outfit usage insights shown on Analytics.
///
/// Reads real outfit data only — `times_worn` (maintained by the database
/// `wear_outfit` RPC) and `last_worn_date` (derived from the shared
/// `wear_log` records in [OutfitRepository]). Nothing here writes to the
/// Outfit Builder or OOTD engine.
class OutfitInsightsSection extends ConsumerWidget {
  const OutfitInsightsSection({super.key});

  static const int _recentLimit = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Outfit>> outfits = ref.watch(outfitsProvider);

    return outfits.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: AppLoadingState(showIcon: false, label: 'Loading outfit insights…'),
      ),
      error: (Object _, StackTrace _) => AppErrorState(
        title: 'We could not load outfit insights',
        message: 'Check your connection and try again.',
        onAction: () => ref.invalidate(outfitsProvider),
      ),
      data: (List<Outfit> list) {
        if (list.isEmpty) {
          return const AppEmptyState(
            icon: Icons.auto_awesome_outlined,
            title: 'No outfit insights yet',
            message:
                'Save and wear outfits to see usage insights here. Wear activity '
                'for outfit pieces is still recorded on this page.',
          );
        }

        final Outfit? mostWorn = _mostWorn(list);
        final List<Outfit> recentlyWorn = _recentlyWorn(list);
        final int neverWorn = list
            .where((Outfit outfit) => outfit.timesWorn <= 0)
            .length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AppSectionHeader(
              'Outfit insights',
              subtitle: '${list.length} saved '
                  'outfit${list.length == 1 ? '' : 's'}',
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: <Widget>[
                  _OutfitInsightRow(
                    icon: Icons.auto_awesome_outlined,
                    label: 'Saved outfits',
                    value: '${list.length}',
                  ),
                  if (mostWorn != null) ...<Widget>[
                    const Divider(),
                    _OutfitInsightRow(
                      icon: Icons.local_fire_department_outlined,
                      label: 'Most worn outfit',
                      value: _outfitName(mostWorn),
                      detail: '${mostWorn.timesWorn} '
                          'wear${mostWorn.timesWorn == 1 ? '' : 's'}',
                    ),
                  ],
                  if (recentlyWorn.isNotEmpty) ...<Widget>[
                    const Divider(),
                    _OutfitInsightRow(
                      icon: Icons.schedule_outlined,
                      label: 'Last outfit worn',
                      value: formatWearDate(recentlyWorn.first.lastWornDate!),
                    ),
                  ],
                  if (neverWorn > 0) ...<Widget>[
                    const Divider(),
                    _OutfitInsightRow(
                      icon: Icons.inventory_2_outlined,
                      label: 'Never worn',
                      value: '$neverWorn of ${list.length}',
                    ),
                  ],
                ],
              ),
            ),
            if (recentlyWorn.length > 1) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: <Widget>[
                    for (int index = 0; index < recentlyWorn.length; index++)
                      ...<Widget>[
                        if (index > 0)
                          const Divider(
                            height: 1,
                            indent: 76,
                            endIndent: AppSpacing.lg,
                          ),
                        _RecentlyWornTile(outfit: recentlyWorn[index]),
                      ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Outfit? _mostWorn(List<Outfit> outfits) {
    final List<Outfit> worn = outfits
        .where((Outfit outfit) => outfit.timesWorn > 0)
        .toList();
    if (worn.isEmpty) {
      return null;
    }
    worn.sort(
      (Outfit a, Outfit b) => b.timesWorn.compareTo(a.timesWorn),
    );
    return worn.first;
  }

  List<Outfit> _recentlyWorn(List<Outfit> outfits) {
    final List<Outfit> worn = outfits
        .where((Outfit outfit) => outfit.lastWornDate != null)
        .toList();
    worn.sort(
      (Outfit a, Outfit b) =>
          b.lastWornDate!.compareTo(a.lastWornDate!),
    );
    return worn.take(_recentLimit).toList();
  }

  String _outfitName(Outfit outfit) =>
      outfit.name?.isNotEmpty == true ? outfit.name! : 'Untitled outfit';
}

class _OutfitInsightRow extends StatelessWidget {
  const _OutfitInsightRow({
    required this.icon,
    required this.label,
    required this.value,
    this.detail,
  });

  final IconData icon;
  final String label;

  /// Right-aligned primary value. For names that can be long the row renders
  /// them as a full-width detail line instead so nothing overflows.
  final String value;

  /// Optional full-width supporting line rendered under [label].
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium,
                ),
                if (detail != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    detail!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            flex: 2,
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentlyWornTile extends StatelessWidget {
  const _RecentlyWornTile({required this.outfit});

  final Outfit outfit;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      leading: SizedBox(
        width: 44,
        height: 44,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: GarmentImage(imageUrl: outfit.coverPhotoUrl),
        ),
      ),
      title: Text(
        outfit.name?.isNotEmpty == true ? outfit.name! : 'Untitled outfit',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        'Worn ${formatWearDate(outfit.lastWornDate!)}',
        style: text.bodySmall,
      ),
      trailing: Text(
        '${outfit.timesWorn} wear${outfit.timesWorn == 1 ? '' : 's'}',
        style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}