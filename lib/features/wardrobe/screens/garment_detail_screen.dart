import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/garment_image.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/garment_status_widgets.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/wear_history_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class GarmentDetailScreen extends ConsumerWidget {
  const GarmentDetailScreen({super.key, required this.garmentId});
  final String garmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wearState = ref.watch(wearLogControllerProvider);
    final history = ref.watch(garmentWearHistoryProvider(garmentId));
    return ref
        .watch(garmentProvider(garmentId))
        .when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, _) => Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Text('This garment could not be loaded.'),
            ),
          ),
          data: (Garment garment) => Scaffold(
            appBar: AppBar(
              actions: <Widget>[
                IconButton(
                  onPressed: () =>
                      context.push('/garments/$garmentId/edit', extra: garment),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit garment',
                ),
                IconButton(
                  onPressed: () => _archive(context, ref, garment),
                  icon: const Icon(Icons.archive_outlined),
                  tooltip: 'Archive garment',
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: <Widget>[
                AspectRatio(
                  aspectRatio: 1,
                  child: GarmentImage(imageUrl: garment.coverImageUrl),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        garment.name,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            <String?>[
                                  garment.category.label,
                                  garment.colorName,
                                  garment.size,
                                ]
                                .whereType<String>()
                                .map((String text) => Chip(label: Text(text)))
                                .toList(),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: wearState.isLoading
                            ? null
                            : () => _markAsWorn(context, ref),
                        icon: wearState.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: Text(
                          wearState.isLoading ? 'Recording...' : 'Mark as Worn',
                        ),
                      ),
                      const SizedBox(height: 28),
                      _Section(
                        title: 'Wear statistics',
                        child: WearStatsRow(garment: garment),
                      ),
                      const SizedBox(height: 24),
                      _Section(
                        title: 'Laundry status',
                        child: LaundryStatusPill(status: garment.laundryStatus),
                      ),
                      const SizedBox(height: 24),
                      _Section(
                        title: 'Wear history',
                        child: history.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.all(12),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (_, _) => TextButton.icon(
                            onPressed: () => ref.invalidate(
                              garmentWearHistoryProvider(garmentId),
                            ),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry loading wear history'),
                          ),
                          data: (history) => WearHistoryList(history: history),
                        ),
                      ),
                      if (garment.price != null ||
                          garment.purchaseDate != null ||
                          garment.brand != null) ...<Widget>[
                        const SizedBox(height: 24),
                        _Section(
                          title: 'Purchase information',
                          child: _DetailsList(
                            values: <String, String?>{
                              'Brand': garment.brand,
                              'Price': garment.price == null
                                  ? null
                                  : '${garment.currency} ${garment.price!.toStringAsFixed(0)}',
                              'Purchased': garment.purchaseDate == null
                                  ? null
                                  : _formatDate(garment.purchaseDate!),
                            },
                          ),
                        ),
                      ],
                      if (garment.fabric != null ||
                          garment.washInstructions != null) ...<Widget>[
                        const SizedBox(height: 24),
                        _Section(
                          title: 'Care information',
                          child: _DetailsList(
                            values: <String, String?>{
                              'Fabric': garment.fabric,
                              'Instructions': garment.washInstructions,
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
  }

  Future<void> _markAsWorn(BuildContext context, WidgetRef ref) async {
    await ref.read(wearLogControllerProvider.notifier).markAsWorn(garmentId);
    if (!context.mounted) return;
    final AsyncValue<void> state = ref.read(wearLogControllerProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not record this wear.')),
      );
      return;
    }
    ref.invalidate(garmentProvider(garmentId));
    ref.invalidate(garmentsProvider);
    ref.invalidate(garmentWearHistoryProvider(garmentId));
    ref.invalidate(recentWearActivityProvider);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Wear recorded.')));
  }

  Future<void> _archive(
    BuildContext context,
    WidgetRef ref,
    Garment garment,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Archive this garment?'),
        content: const Text(
          'It will be removed from your wardrobe but kept safely in your account.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(garmentRepositoryProvider).archiveGarment(garment.id);
      ref.invalidate(garmentsProvider);
      ref.invalidate(garmentProvider(garment.id));
      if (context.mounted) {
        context.pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Garment archived.')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not archive this garment.')),
        );
      }
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      child,
    ],
  );
}

class _DetailsList extends StatelessWidget {
  const _DetailsList({required this.values});
  final Map<String, String?> values;

  @override
  Widget build(BuildContext context) => Column(
    children: values.entries
        .where((MapEntry<String, String?> entry) => entry.value != null)
        .map(
          (MapEntry<String, String?> entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: 104,
                  child: Text(
                    entry.key,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(child: Text(entry.value!)),
              ],
            ),
          ),
        )
        .toList(),
  );
}
