import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/analytics.dart';
import 'package:digital_wardrobe_app/features/analytics/widgets/analytics_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(analyticsSummaryProvider);
    final costs = ref.watch(costPerWearProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: summary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _AnalyticsFeedback(
          title: 'We could not load analytics',
          message: 'Check your connection and try again.',
          action: () => ref.invalidate(analyticsSummaryProvider),
        ),
        data: (AnalyticsSummary data) {
          if (data.totalGarments == 0) {
            return const _AnalyticsFeedback(
              title: 'No wardrobe data yet',
              message:
                  'Add garments and record wears to see your insights here.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(analyticsSummaryProvider);
              ref.invalidate(costPerWearProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: <Widget>[
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: <Widget>[
                    StatCard(
                      label: 'Total garments',
                      value: '${data.totalGarments}',
                    ),
                    StatCard(
                      label: 'Active garments',
                      value: '${data.activeGarments}',
                    ),
                    StatCard(
                      label: 'Archived garments',
                      value: '${data.archivedGarments}',
                    ),
                    StatCard(label: 'Total wears', value: '${data.totalWears}'),
                    StatCard(
                      label: 'Wardrobe value',
                      value: data.totalValue?.toStringAsFixed(0) ?? '—',
                    ),
                    StatCard(
                      label: 'Average cost per wear',
                      value: data.averageCostPerWear?.toStringAsFixed(0) ?? '—',
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                AnalyticsSection(
                  title: 'Garment usage',
                  child: Column(
                    children: <Widget>[
                      _UsageRow(
                        label: 'Most worn',
                        name: data.mostWornName,
                        wears: data.mostWornCount,
                      ),
                      const Divider(),
                      _UsageRow(
                        label: 'Least worn',
                        name: data.leastWornName,
                        wears: data.leastWornCount,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                AnalyticsSection(
                  title: 'Cost per wear',
                  child: costs.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (_, _) => TextButton.icon(
                      onPressed: () => ref.invalidate(costPerWearProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry cost-per-wear data'),
                    ),
                    data: (List<CostPerWearEntry> entries) => entries.isEmpty
                        ? const Text(
                            'Add a purchase price to garments to track cost per wear.',
                          )
                        : Column(
                            children: entries
                                .map(
                                  (CostPerWearEntry entry) =>
                                      CostPerWearRow(entry: entry),
                                )
                                .toList(),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({
    required this.label,
    required this.name,
    required this.wears,
  });
  final String label;
  final String? name;
  final int? wears;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: Text(name ?? 'No garments available'),
    trailing: wears == null ? null : Text('$wears wears'),
  );
}

class _AnalyticsFeedback extends StatelessWidget {
  const _AnalyticsFeedback({
    required this.title,
    required this.message,
    this.action,
  });
  final String title;
  final String message;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.insights_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...<Widget>[
            const SizedBox(height: 20),
            FilledButton(onPressed: action, child: const Text('Retry')),
          ],
        ],
      ),
    ),
  );
}
