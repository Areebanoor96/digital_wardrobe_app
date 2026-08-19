import 'dart:async';

import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/wear_log.dart';
import 'package:digital_wardrobe_app/features/alerts/providers/alerts_provider.dart'
    as alerts;
import 'package:digital_wardrobe_app/features/ootd/services/outfit_recommendation_service.dart';
import 'package:digital_wardrobe_app/features/outfits/models/outfit_context.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final StateProvider<OutfitContext> ootdContextProvider =
    StateProvider<OutfitContext>((Ref ref) => const OutfitContext());

final ootdProvider = FutureProvider<OutfitRecommendation>((Ref ref) {
  final List<Garment> garments =
      ref.watch(garmentsProvider).valueOrNull ?? const <Garment>[];

  final List<WearLog> recentLogs =
      ref.watch(recentWearActivityProvider).valueOrNull ?? const <WearLog>[];

  final OutfitContext context = ref.watch(ootdContextProvider);

  final Set<String> recentlyWornIds = recentLogs
      .map((WearLog log) => log.garmentId)
      .toSet();

  const OutfitRecommendationService service = OutfitRecommendationService();

  final String? memberId = ref.watch(selectedFamilyMemberProvider)?.id;

  if (!service.isEligibleForRecommendation(garments, memberId: memberId)) {
    return const OutfitRecommendation(
      garments: <Garment>[],
      reason:
          'Add at least 5 garments including a top, bottom and shoes '
          'to get an outfit suggestion.',
    );
  }

  return service.recommend(
    allGarments: garments,
    recentlyWornGarmentIds: recentlyWornIds,
    context: context,
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
      ref.invalidate(calendarMonthProvider);
      ref.invalidate(selectedDayWearHistoryProvider);
      ref.invalidate(analyticsSummaryProvider);
      ref.invalidate(alerts.alertsProvider);

      for (final Garment garment in garments) {
        ref.invalidate(garmentProvider(garment.id));
        ref.invalidate(garmentWearHistoryProvider(garment.id));
      }
    }
  }
}
