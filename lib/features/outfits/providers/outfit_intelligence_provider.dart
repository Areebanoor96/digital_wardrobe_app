import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/outfits/models/outfit_context.dart';
import 'package:digital_wardrobe_app/features/outfits/models/outfit_intelligence_recommendation.dart';
import 'package:digital_wardrobe_app/features/outfits/services/outfit_intelligence_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<OutfitIntelligenceEngine> outfitIntelligenceEngineProvider =
Provider<OutfitIntelligenceEngine>(
      (Ref ref) => const OutfitIntelligenceEngine(),
);

final StateProvider<OutfitContext> outfitContextProvider =
StateProvider<OutfitContext>(
      (Ref ref) => const OutfitContext(),
);

final Provider<OutfitIntelligenceRecommendation?>
outfitRecommendationProvider =
Provider<OutfitIntelligenceRecommendation?>((Ref ref) {
  final List<Garment> garments =
      ref.watch(garmentsProvider).valueOrNull ?? const <Garment>[];

  final OutfitContext context = ref.watch(outfitContextProvider);

  if (garments.isEmpty) {
    return null;
  }

  return ref
      .watch(outfitIntelligenceEngineProvider)
      .recommend(
    garments: garments,
    context: context,
  );
});