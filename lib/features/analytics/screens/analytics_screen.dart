import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/core/services/currency_formatter.dart';
import 'package:digital_wardrobe_app/core/theme/app_spacing.dart';
import 'package:digital_wardrobe_app/core/widgets/app_empty_state.dart';
import 'package:digital_wardrobe_app/core/widgets/app_loading_state.dart';
import 'package:digital_wardrobe_app/core/widgets/app_section_header.dart';
import 'package:digital_wardrobe_app/core/widgets/back_arrow_button.dart';
import 'package:digital_wardrobe_app/data/models/analytics.dart';
import 'package:digital_wardrobe_app/features/analytics/widgets/analytics_metric_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.xxxl,
              ),
              children: <Widget>[
                _KeyMetricsGrid(data: data, formatter: formatter),
                const SizedBox(height: AppSpacing.xxl),
                _CategoryBreakdown(data: data),
                const SizedBox(height: AppSpacing.xxl),
                _WearRanking(data: data),
                const SizedBox(height: AppSpacing.xxl),
                _GarmentUsageInsights(data: data, formatter: formatter),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Key Metrics Grid
// ---------------------------------------------------------------------------

class _KeyMetricsGrid extends StatelessWidget {
  const _KeyMetricsGrid({required this.data, required this.formatter});

  final AnalyticsSummary data;
  final CurrencyFormatter formatter;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double spacing = AppSpacing.md;
        final double cardWidth =
            constraints.maxWidth >= spacing
                ? (constraints.maxWidth - spacing) / 2
                : constraints.maxWidth;
        final double? avgWears =
            data.activeGarments > 0
                ? data.totalWears / data.activeGarments
                : null;

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
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: AnalyticsMetricCard(
                title: 'Active',
                value: '${data.activeGarments}',
                icon: Icons.inventory_2_outlined,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: AnalyticsMetricCard(
                title: 'Total wears',
                value: '${data.totalWears}',
                icon: Icons.bar_chart_outlined,
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
                ),
              ),
            if (avgWears != null && avgWears > 0)
              SizedBox(
                width: cardWidth,
                child: AnalyticsMetricCard(
                  title: 'Avg wears per garment',
                  value: avgWears.toStringAsFixed(1),
                  icon: Icons.straighten_outlined,
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
