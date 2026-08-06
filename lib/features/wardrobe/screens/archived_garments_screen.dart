import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/garment_card.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/wardrobe_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ArchivedGarmentsScreen extends ConsumerWidget {
  const ArchivedGarmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Garment>> archived = ref.watch(
      archivedGarmentsProvider,
    );

    final AsyncValue<void> mutationState = ref.watch(
      garmentArchiveControllerProvider,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Closet Vault')),
      body: archived.when(
        loading: () => const GarmentGridShimmer(),
        error: (_, _) => WardrobeEmptyState(
          title: 'Could not load Closet Vault',
          message: 'Check your connection and try again.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(archivedGarmentsProvider),
        ),
        data: (List<Garment> garments) {
          if (garments.isEmpty) {
            return const WardrobeEmptyState(
              title: 'Closet Vault is empty',
              message:
                  'Garments that you move to Closet Vault will appear here '
                  'and can be restored to your wardrobe later.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(archivedGarmentsProvider);
              await ref.read(archivedGarmentsProvider.future);
            },
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              itemCount: garments.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: .62,
              ),
              itemBuilder: (BuildContext context, int index) {
                final Garment garment = garments[index];

                return GarmentCard(
                  garment: garment,
                  showArchivedBadge: true,
                  actionIcon: Icons.unarchive_outlined,
                  actionTooltip: 'Restore to Wardrobe',
                  onAction: mutationState.isLoading
                      ? null
                      : () => _restoreGarment(context, ref, garment),
                  onTap: () => context.push('/garments/${garment.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _restoreGarment(
    BuildContext context,
    WidgetRef ref,
    Garment garment,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Restore ${garment.name}?'),
          content: const Text(
            'This garment will return to the active wardrobe.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Restore'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await ref
        .read(garmentArchiveControllerProvider.notifier)
        .restore(garmentId: garment.id);

    if (!context.mounted) {
      return;
    }

    final AsyncValue<void> state = ref.read(garmentArchiveControllerProvider);

    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not restore this garment.')),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${garment.name} was restored.')));
  }
}
