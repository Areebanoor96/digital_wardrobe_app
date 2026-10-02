import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/core/services/currency_formatter.dart';
import 'package:digital_wardrobe_app/core/theme/app_radius.dart';
import 'package:digital_wardrobe_app/core/theme/app_spacing.dart';
import 'package:digital_wardrobe_app/core/widgets/app_empty_state.dart';
import 'package:digital_wardrobe_app/core/widgets/app_loading_state.dart';
import 'package:digital_wardrobe_app/core/widgets/app_section_header.dart';
import 'package:digital_wardrobe_app/core/widgets/back_arrow_button.dart';
import 'package:digital_wardrobe_app/data/models/analytics.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/wear_log.dart';
import 'package:digital_wardrobe_app/features/analytics/widgets/analytics_metric_card.dart';
import 'package:digital_wardrobe_app/features/analytics/widgets/outfit_insights_section.dart';
import 'package:digital_wardrobe_app/features/analytics/widgets/wear_activity_section.dart';
import 'package:digital_wardrobe_app/features/shell/screens/app_shell_screen.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/garment_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({
    super.key,
    this.canNavigateBack = false,
    this.onNavigateBack,
  });

  final bool canNavigateBack;
  final VoidCallback? onNavigateBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AnalyticsSummary> summary = ref.watch(
      analyticsSummaryProvider,
    );
    final CurrencyFormatter formatter = ref.watch(userCurrencyProvider);

    return Scaffold(
      appBar: AppBar(
        leading: canNavigateBack
            ? BackArrowButton(onPressed: onNavigateBack)
            : null,
        title: const Text('Analytics'),
      ),
      body: summary.when(
        loading: () => const AppLoadingState(label: 'Loading insights…'),
        error: (Object error, StackTrace _) => AppErrorState(
          title: 'We could not load analytics',
          message: 'Check your connection and try again.',
          onAction: () => ref.invalidate(analyticsSummaryProvider),
        ),
        data: (AnalyticsSummary data) {
          if (data.totalGarments == 0) {
            return const AppEmptyState(
              icon: Icons.insights_outlined,
              title: 'No wardrobe data yet',
              message:
                  'Add garments and record wears to see your insights here.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(analyticsSummaryProvider);
              ref.invalidate(recentWearActivityProvider);
              ref.invalidate(outfitsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.xxxl,
              ),
              children: <Widget>[
                _KeyMetricsGrid(
                  data: data,
                  formatter: formatter,
                  onTotalGarmentsTap: () => _openWardrobe(context, ref),
                  onActiveTap: () => _openWardrobe(context, ref),
                  onWearHistoryTap: () => _openWearHistory(context),
                  onVaultTap: () => context.push('/garments/archived'),
                ),
                const SizedBox(height: AppSpacing.xxl),
                _CategoryBreakdown(data: data),
                const SizedBox(height: AppSpacing.xxl),
                _WearRanking(data: data),
                const SizedBox(height: AppSpacing.xxl),
                const WearActivitySection(),
                const SizedBox(height: AppSpacing.xxl),
                const OutfitInsightsSection(),
                const SizedBox(height: AppSpacing.xxl),
                _GarmentUsageInsights(data: data, formatter: formatter),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Switches the shell back to the Wardrobe tab. Analytics is usually pushed
  /// on top of the shell, so after the request the screen is popped to reveal
  /// the freshly-selected tab underneath.
  void _openWardrobe(BuildContext context, WidgetRef ref) {
    ref.read(shellTabRequestProvider.notifier).state = 0;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  /// Opens a bottom sheet with a per-garment wear breakdown built from the
  /// existing recent-wear activity provider.
  void _openWearHistory(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext sheetContext) => const _WearHistorySheet(),
    );
  }
}

// ---------------------------------------------------------------------------
// Key Metrics Grid
// ---------------------------------------------------------------------------

class _KeyMetricsGrid extends StatelessWidget {
  const _KeyMetricsGrid({
    required this.data,
    required this.formatter,
    required this.onTotalGarmentsTap,
    required this.onActiveTap,
    required this.onWearHistoryTap,
    required this.onVaultTap,
  });

  final AnalyticsSummary data;
  final CurrencyFormatter formatter;
  final VoidCallback onTotalGarmentsTap;
  final VoidCallback onActiveTap;
  final VoidCallback onWearHistoryTap;
  final VoidCallback onVaultTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double spacing = AppSpacing.md;
        final double cardWidth =
            constraints.maxWidth >= spacing
                ? (constraints.maxWidth - spacing) / 2
                : constraints.maxWidth;
        // final double? avgWears =
        //     data.activeGarments > 0
        //         ? data.totalWears / data.activeGarments
        //         : null;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: <Widget>[
            SizedBox(
              width: cardWidth,
              child: AnalyticsMetricCard(
                title: 'Total garments',
                value: '${data.totalGarments}',
                icon: Icons.checkroom_outlined,
                onTap: onTotalGarmentsTap,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: AnalyticsMetricCard(
                title: 'Active',
                value: '${data.activeGarments}',
                icon: Icons.inventory_2_outlined,
                color: Theme.of(context).colorScheme.tertiary,
                onTap: onActiveTap,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: AnalyticsMetricCard(
                title: 'Total wears',
                value: '${data.totalWears}',
                icon: Icons.bar_chart_outlined,
                onTap: onWearHistoryTap,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: AnalyticsMetricCard(
                title: 'Wardrobe value',
                value: formatter.format(data.totalValue),
                icon: Icons.payments_outlined,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
            if (data.archivedGarments > 0)
              SizedBox(
                width: cardWidth,
                child: AnalyticsMetricCard(
                  title: 'Closet Vault',
                  value: '${data.archivedGarments}',
                  icon: Icons.archive_outlined,
                  color: Theme.of(context).colorScheme.outline,
                  onTap: onVaultTap,
                ),
              ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Category Breakdown
// ---------------------------------------------------------------------------

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.data});

  final AnalyticsSummary data;

  @override
  Widget build(BuildContext context) {
    if (data.categoryDistribution.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<MapEntry<String, int>> sorted =
        data.categoryDistribution.entries.toList()
          ..sort(
            (MapEntry<String, int> a, MapEntry<String, int> b) =>
                b.value.compareTo(a.value),
          );
    final int maxCount = sorted.first.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const AppSectionHeader('Category breakdown'),
        const SizedBox(height: AppSpacing.sm),
        ...sorted.map((MapEntry<String, int> entry) {
          final double fraction = maxCount > 0 ? entry.value / maxCount : 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        entry.key,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '${entry.value}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 6,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Wear Ranking
// ---------------------------------------------------------------------------

class _WearRanking extends StatelessWidget {
  const _WearRanking({required this.data});

  final AnalyticsSummary data;

  @override
  Widget build(BuildContext context) {
    if (data.mostWornName == null && data.leastWornName == null) {
      return const SizedBox.shrink();
    }

    final List<_WearRankItem> items = <_WearRankItem>[
      if (data.mostWornName != null)
        _WearRankItem(
          label: 'Most worn',
          name: data.mostWornName!,
          wears: data.mostWornCount,
        ),
      if (data.leastWornName != null && data.leastWornName != data.mostWornName)
        _WearRankItem(
          label: 'Least worn',
          name: data.leastWornName!,
          wears: data.leastWornCount,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const AppSectionHeader('Garment usage'),
        const SizedBox(height: AppSpacing.sm),
        ...items.map((_WearRankItem item) {
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  item.label == 'Most worn'
                      ? Icons.trending_up
                      : Icons.trending_down,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: Text(
                item.name,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(item.label),
              trailing: item.wears != null
                  ? Text(
                      '${item.wears} wears',
                      style: Theme.of(context).textTheme.labelMedium,
                    )
                  : null,
            ),
          );
        }),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Garment Usage Insights
// ---------------------------------------------------------------------------

class _GarmentUsageInsights extends StatelessWidget {
  const _GarmentUsageInsights({
    required this.data,
    required this.formatter,
  });

  final AnalyticsSummary data;
  final CurrencyFormatter formatter;

  @override
  Widget build(BuildContext context) {
    if (data.totalWears == 0) {
      return const SizedBox.shrink();
    }

    final int neverWorn = data.wearDistribution['Never worn'] ?? 0;
    final int mostWornCount = data.mostWornCount ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const AppSectionHeader('Usage insights'),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: <Widget>[
                _UsageInsightRow(
                  icon: Icons.local_fire_department_outlined,
                  label: 'Most worn item',
                  value: '${data.mostWornCount ?? 0} wears',
                ),
                const Divider(),
                if (data.totalValue != null && data.totalWears > 0)
                  _UsageInsightRow(
                    icon: Icons.payments_outlined,
                    label: 'Avg cost per wear',
                    value: formatter.format(data.totalValue! / data.totalWears),
                  ),
                if (data.totalValue != null && data.totalWears > 0)
                  const Divider(),
                _UsageInsightRow(
                  icon: Icons.checkroom_outlined,
                  label: 'Never worn',
                  value: '$neverWorn of ${data.activeGarments}',
                ),
                if (neverWorn > 0 && data.activeGarments > 0) ...<Widget>[
                  const Divider(),
                  _UsageInsightRow(
                    icon: Icons.inventory_2_outlined,
                    label: 'Utilization',
                    value:
                        '${(((data.activeGarments - neverWorn) / data.activeGarments) * 100).round()}%',
                  ),
                ],
                if (data.leastWornName != null &&
                    data.leastWornCount != null &&
                    data.leastWornCount! > 0) ...<Widget>[
                  const Divider(),
                  _UsageInsightRow(
                    icon: Icons.schedule_outlined,
                    label: 'Wears of least worn',
                    value: '${data.leastWornCount} wears',
                  ),
                ],
                if (mostWornCount > 1 && data.leastWornCount != null) ...<Widget>[
                  const Divider(),
                  _UsageInsightRow(
                    icon: Icons.compare_arrows_outlined,
                    label: 'Most vs least worn',
                    value: '$mostWornCount vs ${data.leastWornCount}',
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

class _UsageInsightRow extends StatelessWidget {
  const _UsageInsightRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _WearRankItem {
  const _WearRankItem({
    required this.label,
    required this.name,
    this.wears,
  });

  final String label;
  final String name;
  final int? wears;
}

// ---------------------------------------------------------------------------
// Wear History Bottom Sheet
// ---------------------------------------------------------------------------

/// Detailed wear-history modal: groups the recent wear activity by garment so
/// each garment shows its individual wear breakdown (count + last worn date).
/// Reuses the existing [recentWearActivityProvider] and [garmentsProvider] —
/// no new queries are issued.
class _WearHistorySheet extends ConsumerWidget {
  const _WearHistorySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AsyncValue<List<WearLog>> activity = ref.watch(
      recentWearActivityProvider,
    );
    final List<Garment> garments =
        ref.watch(garmentsProvider).valueOrNull ?? const <Garment>[];

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xs,
            AppSpacing.xl,
            AppSpacing.xxxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Wear history',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Individual garment wear breakdown',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              activity.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                  child: Center(
                    child: AppLoadingState(
                      showIcon: false,
                      label: 'Loading wear history',
                    ),
                  ),
                ),
                error: (_, _) => Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xxl,
                  ),
                  child: Center(
                    child: Text(
                      'Could not load wear history.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                data: (List<WearLog> logs) {
                  if (logs.isEmpty) {
                    return const AppEmptyState(
                      icon: Icons.history,
                      title: 'No wear history yet',
                      message:
                          'Wear records will appear here as you mark '
                          'garments as worn.',
                    );
                  }

                  final List<_GarmentWearEntry> entries = _groupBreakdown(
                    logs,
                    garments,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (
                        int index = 0;
                        index < entries.length;
                        index++
                      ) ...<Widget>[
                        if (index > 0)
                          const Divider(
                            height: 1,
                            indent: 68,
                            endIndent: 0,
                          ),
                        _WearBreakdownTile(entry: entries[index]),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GarmentWearEntry {
  const _GarmentWearEntry({
    required this.garment,
    required this.count,
    required this.lastWorn,
  });

  final Garment? garment;
  final int count;
  final DateTime lastWorn;
}

List<_GarmentWearEntry> _groupBreakdown(
  List<WearLog> logs,
  List<Garment> garments,
) {
  final Map<String, List<WearLog>> byGarment = <String, List<WearLog>>{};
  for (final WearLog log in logs) {
    byGarment.putIfAbsent(log.garmentId, () => <WearLog>[]).add(log);
  }

  final List<_GarmentWearEntry> entries = <_GarmentWearEntry>[];
  byGarment.forEach((String garmentId, List<WearLog> garmentLogs) {
    garmentLogs.sort((WearLog a, WearLog b) => b.wornDate.compareTo(a.wornDate));
    final Garment? garment = _garmentById(garments, garmentId);
    entries.add(
      _GarmentWearEntry(
        garment: garment,
        count: garmentLogs.length,
        lastWorn: garmentLogs.first.wornDate,
      ),
    );
  });

  entries.sort(
    (_GarmentWearEntry a, _GarmentWearEntry b) =>
        b.lastWorn.compareTo(a.lastWorn),
  );
  return entries;
}

Garment? _garmentById(List<Garment> garments, String garmentId) {
  for (final Garment garment in garments) {
    if (garment.id == garmentId) {
      return garment;
    }
  }
  return null;
}

class _WearBreakdownTile extends StatelessWidget {
  const _WearBreakdownTile({required this.entry});

  final _GarmentWearEntry entry;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 0,
        vertical: AppSpacing.xs,
      ),
      leading: SizedBox(
        width: 48,
        height: 48,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: GarmentImage(imageUrl: entry.garment?.coverImageUrl),
        ),
      ),
      title: Text(
        entry.garment?.name ?? 'In Closet Vault',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${entry.count} wear${entry.count == 1 ? '' : 's'}',
        style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
      trailing: Text(
        formatWearDate(entry.lastWorn),
        style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}
