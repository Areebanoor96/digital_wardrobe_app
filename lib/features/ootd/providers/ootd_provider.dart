import 'dart:async';

import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/wear_log.dart';
import 'package:digital_wardrobe_app/features/ootd/services/outfit_recommendation_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ootdProvider = FutureProvider<OutfitRecommendation>((Ref ref) {
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
});

final ootdActionControllerProvider =
    AutoDisposeAsyncNotifierProvider<OotdActionController, void>(
      OotdActionController.new,
    );

class OotdActionController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> saveAsOutfit(List<Garment> garments, {String? name}) async {
    final selectedMember = ref.read(selectedFamilyMemberProvider);

    if (selectedMember == null) {
      state = AsyncError<void>(
        StateError('No wardrobe profile is selected.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading<void>();

    state = await AsyncValue.guard(() async {
      await ref
          .read(outfitRepositoryProvider)
          .saveOutfit(
            memberId: selectedMember.id,
            name: name ?? 'OOTD Recommendation',
            garmentIds: garments.map((Garment garment) => garment.id).toList(),
          );

      ref.invalidate(outfitsProvider);
    });
  }

  Future<void> wearOutfit(
    List<Garment> garments, {
    String eventName = 'OOTD',
    LaundryStatus laundryStatusAfter = LaundryStatus.dirty,
    String? notes,
  }) async {
    final selectedMember = ref.read(selectedFamilyMemberProvider);

    if (selectedMember == null) {
      state = AsyncError<void>(
        StateError('No wardrobe profile is selected.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading<void>();

    state = await AsyncValue.guard(() async {
      for (final Garment garment in garments) {
        await ref
            .read(wearLogRepositoryProvider)
            .createWearLog(
              memberId: selectedMember.id,
              garmentId: garment.id,
              eventName: eventName,
              laundryStatusAfter: laundryStatusAfter,
              notes: notes,
            );
      }
    });

    if (!state.hasError) {
      ref.invalidate(garmentsProvider);
      ref.invalidate(recentWearActivityProvider);
      ref.invalidate(analyticsSummaryProvider);

      for (final Garment garment in garments) {
        ref.invalidate(garmentProvider(garment.id));
        ref.invalidate(garmentWearHistoryProvider(garment.id));
      }
    }
  }
}
