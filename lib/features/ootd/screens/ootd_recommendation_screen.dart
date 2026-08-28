import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/core/widgets/back_arrow_button.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/ootd_recommendation_snapshot.dart';
import 'package:digital_wardrobe_app/features/ootd/providers/ootd_provider.dart';
import 'package:digital_wardrobe_app/features/ootd/widgets/ootd_card.dart';
import 'package:digital_wardrobe_app/features/outfits/models/outfit_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OotdRecommendationScreen extends ConsumerWidget {
  const OotdRecommendationScreen({super.key, required this.snapshotId});

  final String snapshotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<RestoredOotdRecommendation> snapshot = ref.watch(
      ootdRecommendationSnapshotProvider(snapshotId),
    );
    final AsyncValue<void> actionState = ref.watch(ootdActionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const BackArrowButton(),
        title: const Text('Outfit Suggestion'),
      ),
      body: snapshot.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _SnapshotFeedback(
          title: 'Suggestion unavailable',
          message: 'This outfit suggestion could not be loaded.',
          actionLabel: 'Retry',
          onAction: () {
            ref.invalidate(ootdRecommendationSnapshotProvider(snapshotId));
          },
        ),
        data: (RestoredOotdRecommendation restored) {
          final List<Garment> garments = restored.garments;
          final bool canUse = restored.canUseRecommendation;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: <Widget>[
              if (restored.hasMissingGarments || restored.hasUnavailableGarments)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SnapshotNotice(restored: restored),
                ),
              OotdCard(
                recommendation: restored.recommendation,
                outfitContext: const OutfitContext(),
                onSave: canUse && !actionState.isLoading
                    ? () => ref
                          .read(ootdActionControllerProvider.notifier)
                          .saveAsOutfit(garments)
                    : null,
                onWear: canUse && !actionState.isLoading
                    ? () => ref
                          .read(ootdActionControllerProvider.notifier)
                          .wearOutfit(garments)
                    : null,
                isSaving: actionState.isLoading,
                isWearing: actionState.isLoading,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SnapshotNotice extends StatelessWidget {
  const _SnapshotNotice({required this.restored});

  final RestoredOotdRecommendation restored;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final int missingCount = restored.missingGarmentIds.length;
    final int unavailableCount = restored.unavailableGarmentIds.length;
    final String message = <String>[
      if (missingCount > 0)
        '$missingCount garment${missingCount == 1 ? '' : 's'} could not be found',
      if (unavailableCount > 0)
        '$unavailableCount garment${unavailableCount == 1 ? '' : 's'} is no longer ready to wear',
    ].join('. ');

    return Card(
      elevation: 0,
      color: colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.info_outline, color: colors.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SnapshotFeedback extends StatelessWidget {
  const _SnapshotFeedback({
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
  Widget build(BuildContext context) {
    return Center(
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
}
