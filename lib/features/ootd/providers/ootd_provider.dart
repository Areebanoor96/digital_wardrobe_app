import 'dart:async';

import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/wear_log.dart';
import 'package:digital_wardrobe_app/features/alerts/providers/alerts_provider.dart'
    as alerts;
import 'package:digital_wardrobe_app/features/ootd/models/weather_data.dart';
import 'package:digital_wardrobe_app/features/ootd/providers/weather_provider.dart';
import 'package:digital_wardrobe_app/features/ootd/services/outfit_recommendation_service.dart';
import 'package:digital_wardrobe_app/features/outfits/models/outfit_context.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final StateProvider<OutfitContext> ootdContextProvider =
    StateProvider<OutfitContext>((Ref ref) => const OutfitContext());

final FutureProvider<List<WearLog>> ootdWearHistoryProvider =
    FutureProvider<List<WearLog>>((Ref ref) async {
      final selectedMember = ref.watch(selectedFamilyMemberProvider);

      if (selectedMember == null) {
        return const <WearLog>[];
      }

      return ref
          .watch(wearLogRepositoryProvider)
          .fetchRecommendationWearHistory(memberId: selectedMember.id);
    });

final ootdProvider = FutureProvider<OutfitRecommendation>((Ref ref) {
  final List<Garment> garments =
      ref.watch(garmentsProvider).valueOrNull ?? const <Garment>[];

  final List<WearLog> wearLogs =
      ref.watch(ootdWearHistoryProvider).valueOrNull ?? const <WearLog>[];

  final WeatherData? weather = ref.watch(ootdWeatherProvider).valueOrNull;

  final OutfitContext context = ref.watch(ootdContextProvider);

  const OutfitRecommendationService service = OutfitRecommendationService();

  final String? memberId = ref.watch(selectedFamilyMemberProvider)?.id;

  if (!service.isEligibleForRecommendation(garments, memberId: memberId)) {
    return const OutfitRecommendation(
      garments: <Garment>[],
      reason:
          'Add clean garments that can make either top + bottom + shoes '
          'or dress + shoes to get an outfit suggestion.',
    );
  }

  return service.recommend(
    allGarments: garments,
    wearLogs: wearLogs,
    context: context,
    weather: weather,
    memberId: memberId,
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
    LaundryStatus? laundryStatusAfter,
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
      final WeatherData? weather = ref.read(ootdWeatherProvider).valueOrNull;

      for (final Garment garment in garments) {
        await ref
            .read(wearLogRepositoryProvider)
            .createWearLog(
              memberId: selectedMember.id,
              garmentId: garment.id,
              eventName: eventName,
              laundryStatusAfter: laundryStatusAfter,
              notes: notes,
              weatherTemp: weather?.temperature,
              weatherCondition: weather?.condition,
            );
      }
    });

    if (!state.hasError) {
      ref.invalidate(garmentsProvider);
      ref.invalidate(recentWearActivityProvider);
      ref.invalidate(ootdWearHistoryProvider);
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
