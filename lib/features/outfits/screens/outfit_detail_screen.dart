import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/outfit.dart';
import 'package:digital_wardrobe_app/features/outfits/widgets/outfit_garment_tile.dart';
import 'package:digital_wardrobe_app/features/outfits/widgets/outfit_preview_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OutfitDetailScreen extends ConsumerWidget {
  const OutfitDetailScreen({super.key, required this.outfitId});
  final String outfitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wearState = ref.watch(wearOutfitControllerProvider);
    final garments = ref.watch(garmentsProvider);
    return ref
        .watch(outfitProvider(outfitId))
        .when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, _) => Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('This outfit could not be loaded.')),
          ),
          data: (Outfit outfit) {
            final List<Garment> items = outfit.garmentIds
                .map(
                  (String id) => garments.valueOrNull
                      ?.where((Garment garment) => garment.id == id)
                      .firstOrNull,
                )
                .whereType<Garment>()
                .toList();
            return Scaffold(
              appBar: AppBar(
                actions: <Widget>[
                  IconButton(
                    onPressed: () =>
                        context.push('/outfits/$outfitId/edit', extra: outfit),
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit outfit',
                  ),
                  IconButton(
                    onPressed: () => _delete(context, ref, outfit),
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete outfit',
                  ),
                ],
              ),
              body: ListView(
                padding: const EdgeInsets.all(20),
                children: <Widget>[
                  Center(child: OutfitPreviewGrid(garments: items, size: 180)),
                  const SizedBox(height: 24),
                  Text(
                    outfit.name?.isNotEmpty == true
                        ? outfit.name!
                        : 'Untitled outfit',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${outfit.garmentIds.length} garments · Created ${_formatDate(outfit.createdAt)}',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    outfit.lastWornDate == null
                        ? 'Not worn yet'
                        : 'Last worn ${_formatDate(outfit.lastWornDate)}',
                  ),
                  const SizedBox(height: 4),
                  Text('${outfit.timesWorn} wears'),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: wearState.isLoading
                        ? null
                        : () => _wearOutfit(context, ref, outfit),
                    icon: wearState.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      wearState.isLoading ? 'Recording...' : 'Wear Outfit',
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Garments',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (items.isEmpty)
                    const Text(
                      'The garments in this outfit are no longer available.',
                    )
                  else
                    ...items.map(
                      (Garment garment) => OutfitGarmentTile(garment: garment),
                    ),
                ],
              ),
            );
          },
        );
  }

  Future<void> _wearOutfit(
    BuildContext context,
    WidgetRef ref,
    Outfit outfit,
  ) async {
    await ref.read(wearOutfitControllerProvider.notifier).wearOutfit(outfit);
    if (!context.mounted) return;
    if (ref.read(wearOutfitControllerProvider).hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not record this outfit.')),
      );
      return;
    }
    ref.invalidate(outfitProvider(outfit.id));
    ref.invalidate(outfitsProvider);
    ref.invalidate(garmentsProvider);
    ref.invalidate(recentWearActivityProvider);
    for (final String garmentId in outfit.garmentIds) {
      ref.invalidate(garmentProvider(garmentId));
      ref.invalidate(garmentWearHistoryProvider(garmentId));
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Outfit wear recorded.')));
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Outfit outfit,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete this outfit?'),
        content: const Text(
          'Saved wear logs will remain, but they will no longer be linked to this outfit.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(outfitMutationControllerProvider.notifier).delete(outfit.id);
    if (!context.mounted) return;
    if (ref.read(outfitMutationControllerProvider).hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete this outfit.')),
      );
      return;
    }
    ref.invalidate(outfitsProvider);
    if (context.mounted) context.pop();
  }

  String _formatDate(DateTime? date) => date == null
      ? '—'
      : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
