import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/outfit.dart';
import 'package:digital_wardrobe_app/features/ootd/providers/ootd_provider.dart';
import 'package:digital_wardrobe_app/features/ootd/services/outfit_recommendation_service.dart';
import 'package:digital_wardrobe_app/features/outfits/models/outfit_context.dart';
import 'package:digital_wardrobe_app/features/ootd/widgets/ootd_card.dart';
import 'package:digital_wardrobe_app/features/outfits/widgets/outfit_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OutfitsScreen extends ConsumerWidget {
  const OutfitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outfits = ref.watch(outfitsProvider);
    final garments = ref.watch(garmentsProvider);
    final ootd = ref.watch(ootdProvider);
    final actionState = ref.watch(ootdActionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Outfits')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/outfits/new'),
        icon: const Icon(Icons.add),
        label: const Text('Create outfit'),
      ),
      body: outfits.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _OutfitFeedback(
          title: 'We could not load your outfits',
          message: 'Check your connection and try again.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(outfitsProvider),
        ),
        data: (List<Outfit> saved) {
          final List<Garment> wardrobe =
              garments.valueOrNull ?? const <Garment>[];
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(outfitsProvider);
              ref.invalidate(ootdProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
              children: <Widget>[
                ootd.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Card(
                      elevation: 0,
                      child: SizedBox(
                        height: 180,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (OutfitRecommendation rec) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OotdCard(
                      recommendation: rec,
                      onRefresh: () => ref.invalidate(ootdProvider),
                      outfitContext: ref.watch(ootdContextProvider),
                      onContextChanged: (OutfitContext value) {
                        ref.read(ootdContextProvider.notifier).state = value;
                      },
                      onSave: actionState.isLoading
                          ? null
                          : () => ref
                                .read(ootdActionControllerProvider.notifier)
                                .saveAsOutfit(rec.garments),
                      onWear: actionState.isLoading
                          ? null
                          : () => ref
                                .read(ootdActionControllerProvider.notifier)
                                .wearOutfit(rec.garments),
                      isSaving: actionState.isLoading,
                      isWearing: actionState.isLoading,
                    ),
                  ),
                ),
                if (saved.isEmpty)
                  _OutfitFeedback(
                    title: 'No saved outfits yet',
                    message:
                        'Combine garments from your wardrobe into outfits you can reuse.',
                    actionLabel: 'Create outfit',
                    onAction: () => context.push('/outfits/new'),
                  )
                else
                  ...saved.map((Outfit outfit) {
                    final List<Garment> items = outfit.garmentIds
                        .map(
                          (String id) => wardrobe
                              .where((Garment garment) => garment.id == id)
                              .firstOrNull,
                        )
                        .whereType<Garment>()
                        .toList();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: OutfitCard(
                        outfit: outfit,
                        garments: items,
                        onTap: () => context.push('/outfits/${outfit.id}'),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OutfitFeedback extends StatelessWidget {
  const _OutfitFeedback({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.auto_awesome_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...<Widget>[
            const SizedBox(height: 20),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}
