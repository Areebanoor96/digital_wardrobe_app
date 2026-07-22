import 'dart:async';

import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/wear_log.dart';
import 'package:digital_wardrobe_app/features/ootd/services/outfit_recommendation_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ootdProvider = FutureProvider<OutfitRecommendation>(
  (Ref ref) {
    final List<Garment> garments =
        ref.watch(garmentsProvider).valueOrNull ?? const <Garment>[];
    final List<WearLog> recentLogs =
        ref.watch(recentWearActivityProvider).valueOrNull ?? const <WearLog>[];

    final Set<String> recentlyWornIds = recentLogs
        .map((WearLog log) => log.garmentId)
        .toSet();

    return OutfitRecommendationService().recommend(
      allGarments: garments,
      recentlyWornGarmentIds: recentlyWornIds,
    );
  },
);

final ootdActionControllerProvider =
    AutoDisposeAsyncNotifierProvider<OotdActionController, void>(
  OotdActionController.new,
);

class OotdActionController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> saveAsOutfit(
    List<Garment> garments, {
    String? name,
  }) async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(() async {
      await ref.read(outfitRepositoryProvider).saveOutfit(
        name: name ?? 'OOTD Recommendation',
        garmentIds: garments.map((Garment g) => g.id).toList(),
      );
      ref.invalidate(outfitsProvider);
    });
  }

  Future<void> wearOutfit(List<Garment> garments) async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(() async {
      for (final Garment g in garments) {
        await ref.read(wearLogRepositoryProvider).createWearLog(g.id);
      }
      ref.invalidate(garmentsProvider);
      ref.invalidate(recentWearActivityProvider);
    });
  }
}
