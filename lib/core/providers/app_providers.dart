import 'dart:async';

import 'package:digital_wardrobe_app/core/services/app_info_service.dart';
import 'package:digital_wardrobe_app/core/services/country_currency_service.dart';
import 'package:digital_wardrobe_app/core/services/currency_formatter.dart';
import 'package:digital_wardrobe_app/core/services/image_service.dart';
import 'package:digital_wardrobe_app/core/services/supabase_service.dart';
import 'package:digital_wardrobe_app/data/models/analytics.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/data/models/garment_location.dart';
import 'package:digital_wardrobe_app/data/models/growth_measurement.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/lending_record.dart';
import 'package:digital_wardrobe_app/data/models/ootd_recommendation_snapshot.dart';
import 'package:digital_wardrobe_app/data/models/outfit.dart';
import 'package:digital_wardrobe_app/data/models/profile.dart';
import 'package:digital_wardrobe_app/data/models/wear_log.dart';
import 'package:digital_wardrobe_app/data/repositories/account_repository.dart';
import 'package:digital_wardrobe_app/data/repositories/alerts_repository.dart';
import 'package:digital_wardrobe_app/data/repositories/analytics_repository.dart';
import 'package:digital_wardrobe_app/data/repositories/family_repository.dart';
import 'package:digital_wardrobe_app/data/repositories/garment_location_repository.dart';
import 'package:digital_wardrobe_app/data/repositories/garment_repository.dart';
import 'package:digital_wardrobe_app/data/repositories/lending_repository.dart';
import 'package:digital_wardrobe_app/data/repositories/ootd_recommendation_repository.dart';
import 'package:digital_wardrobe_app/data/repositories/outfit_repository.dart';
import 'package:digital_wardrobe_app/data/repositories/profile_repository.dart';
import 'package:digital_wardrobe_app/data/repositories/wear_log_repository.dart';
import 'package:digital_wardrobe_app/data/repositories/growth_repository.dart';
import 'package:digital_wardrobe_app/features/alerts/providers/alerts_provider.dart'
    as alerts;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final Provider<AppInfoService> appInfoServiceProvider =
    Provider<AppInfoService>((Ref ref) => const AppInfoService());

/// Installed application version/build metadata, exposed centrally so any
/// screen (About, diagnostics, error reporting) can reuse it.
final FutureProvider<AppInfo> appInfoProvider = FutureProvider<AppInfo>(
  (Ref ref) => ref.watch(appInfoServiceProvider).read(),
);

final selectedFamilyMemberProvider = StateProvider<FamilyMember?>(
  (Ref ref) => null,
);

final Provider<ImageService> imageServiceProvider = Provider<ImageService>(
  (Ref ref) => ImageService(ImagePicker()),
);

final Provider<GarmentRepository> garmentRepositoryProvider =
    Provider<GarmentRepository>(
      (Ref ref) => GarmentRepository(SupabaseService.client),
    );

final Provider<GarmentLocationRepository> garmentLocationRepositoryProvider =
    Provider<GarmentLocationRepository>(
      (Ref ref) => GarmentLocationRepository(SupabaseService.client),
    );

final Provider<LendingRepository> lendingRepositoryProvider =
    Provider<LendingRepository>(
      (Ref ref) => LendingRepository(SupabaseService.client),
    );

final Provider<AnalyticsRepository> analyticsRepositoryProvider =
    Provider<AnalyticsRepository>(
      (Ref ref) => AnalyticsRepository(SupabaseService.client),
    );

final Provider<OutfitRepository> outfitRepositoryProvider =
    Provider<OutfitRepository>(
      (Ref ref) => OutfitRepository(SupabaseService.client),
    );

final Provider<ProfileRepository> profileRepositoryProvider =
    Provider<ProfileRepository>(
      (Ref ref) => ProfileRepository(SupabaseService.client),
    );

final Provider<AccountRepository> accountRepositoryProvider =
    Provider<AccountRepository>((Ref ref) => const AccountRepository());

final Provider<FamilyRepository> familyRepositoryProvider =
    Provider<FamilyRepository>(
      (Ref ref) => FamilyRepository(SupabaseService.client),
    );

final Provider<WearLogRepository> wearLogRepositoryProvider =
    Provider<WearLogRepository>(
      (Ref ref) => WearLogRepository(SupabaseService.client),
    );
final Provider<GrowthRepository> growthRepositoryProvider =
    Provider<GrowthRepository>(
      (Ref ref) => GrowthRepository(SupabaseService.client),
    );
final FutureProviderFamily<FamilyMember?, String> familyMemberProvider =
    FutureProvider.family<FamilyMember?, String>((Ref ref, String memberId) {
      return ref.watch(familyRepositoryProvider).getFamilyMemberById(memberId);
    });
final FutureProviderFamily<List<GrowthMeasurement>, String>
growthMeasurementsProvider =
    FutureProvider.family<List<GrowthMeasurement>, String>((
      Ref ref,
      String memberId,
    ) {
      return ref
          .watch(growthRepositoryProvider)
          .fetchMeasurements(memberId: memberId);
    });

final Provider<AlertsRepository> alertsRepositoryProvider =
    Provider<AlertsRepository>(
      (Ref ref) => AlertsRepository(
        SupabaseService.client,
        ootdRecommendationRepository: ref.watch(
          ootdRecommendationRepositoryProvider,
        ),
      ),
    );

final Provider<OotdRecommendationRepository> ootdRecommendationRepositoryProvider =
    Provider<OotdRecommendationRepository>(
      (Ref ref) => OotdRecommendationRepository(
        SupabaseService.client,
        ref.watch(garmentRepositoryProvider),
      ),
    );

final ootdRecommendationSnapshotProvider =
    FutureProvider.family<RestoredOotdRecommendation, String>((
      Ref ref,
      String snapshotId,
    ) {
      final FamilyMember? selectedMember = ref.watch(
        selectedFamilyMemberProvider,
      );

      if (selectedMember == null) {
        throw StateError('No profile selected.');
      }

      return ref
          .watch(ootdRecommendationRepositoryProvider)
          .fetchRestoredRecommendation(
            snapshotId: snapshotId,
            memberId: selectedMember.id,
          );
    });

final FutureProvider<List<Garment>> garmentsProvider =
    FutureProvider<List<Garment>>((Ref ref) async {
      final FamilyMember? selectedMember = ref.watch(
        selectedFamilyMemberProvider,
      );

      if (selectedMember == null) {
        return const <Garment>[];
      }

      return ref
          .watch(garmentRepositoryProvider)
          .fetchGarments(memberId: selectedMember.id);
    });

final FutureProvider<List<GarmentLocation>> garmentLocationsProvider =
    FutureProvider<List<GarmentLocation>>((Ref ref) async {
      final FamilyMember? selectedMember = ref.watch(
        selectedFamilyMemberProvider,
      );

      if (selectedMember == null) {
        return const <GarmentLocation>[];
      }

      return ref
          .watch(garmentLocationRepositoryProvider)
          .fetchLocations(memberId: selectedMember.id);
    });

final FutureProvider<Map<String, int>> familyMemberPieceCountsProvider =
    FutureProvider<Map<String, int>>((Ref ref) {
      return ref
          .watch(garmentRepositoryProvider)
          .fetchActiveGarmentCountsByMember();
    });

final garmentProvider = FutureProvider.family<Garment, String>((
  Ref ref,
  String garmentId,
) async {
  final FamilyMember? selectedMember = ref.watch(selectedFamilyMemberProvider);

  if (selectedMember == null) {
    throw StateError('No profile selected.');
  }

  return ref
      .watch(garmentRepositoryProvider)
      .fetchGarment(id: garmentId, memberId: selectedMember.id);
});

final activeLendingRecordProvider =
    FutureProvider.family<LendingRecord?, String>((Ref ref, String garmentId) {
      final FamilyMember? selectedMember = ref.watch(
        selectedFamilyMemberProvider,
      );

      if (selectedMember == null) {
        return null;
      }

      return ref
          .watch(lendingRepositoryProvider)
          .fetchActiveRecord(memberId: selectedMember.id, garmentId: garmentId);
    });
final FutureProvider<List<Garment>> archivedGarmentsProvider =
    FutureProvider<List<Garment>>((Ref ref) async {
      final FamilyMember? selectedMember = ref.watch(
        selectedFamilyMemberProvider,
      );

      if (selectedMember == null) {
        return const <Garment>[];
      }

      return ref
          .watch(garmentRepositoryProvider)
          .fetchArchivedGarments(memberId: selectedMember.id);
    });

final FutureProvider<List<Outfit>> outfitsProvider =
    FutureProvider<List<Outfit>>((Ref ref) async {
      final FamilyMember? selectedMember = ref.watch(
        selectedFamilyMemberProvider,
      );

      if (selectedMember == null) {
        return const <Outfit>[];
      }

      return ref
          .watch(outfitRepositoryProvider)
          .fetchOutfits(memberId: selectedMember.id);
    });

final outfitProvider = FutureProvider.family<Outfit, String>((
  Ref ref,
  String outfitId,
) async {
  final FamilyMember? selectedMember = ref.watch(selectedFamilyMemberProvider);

  if (selectedMember == null) {
    throw StateError('No profile selected.');
  }

  return ref
      .watch(outfitRepositoryProvider)
      .fetchOutfit(outfitId: outfitId, memberId: selectedMember.id);
});

final profileProvider = FutureProvider.autoDispose<Profile>(
      (Ref ref) => ref.watch(profileRepositoryProvider).fetchProfile(),
);

/// The centralized country → currency mapping used by Setup and Analytics.
final Provider<CountryCurrencyService> countryCurrencyServiceProvider =
    Provider<CountryCurrencyService>(
      (Ref ref) => const CountryCurrencyService(),
);

/// The user's derived currency formatter based on the country saved during the
/// Setup Wizard. Falls back to the default country (PKR) when a user has no
/// stored country. This is a lightweight, cached derivation from
/// [profileProvider] — Analytics never issues a network call for currency.
final Provider<CurrencyFormatter> userCurrencyProvider =
    Provider<CurrencyFormatter>((Ref ref) {
      final AsyncValue<Profile> profile = ref.watch(profileProvider);
      final String? countryCode =
          profile.valueOrNull?.countryCode ??
          CountryCurrencyService.defaultCountry.code;
      return ref.watch(countryCurrencyServiceProvider).formatterFor(countryCode);
    });

final familyMembersProvider =
FutureProvider.autoDispose<List<FamilyMember>>(
      (Ref ref) =>
      ref.watch(familyRepositoryProvider).fetchFamilyMembers(),
);

final garmentWearHistoryProvider = FutureProvider.family<List<WearLog>, String>(
  (Ref ref, String garmentId) async {
    final FamilyMember? selectedMember = ref.watch(
      selectedFamilyMemberProvider,
    );

    if (selectedMember == null) {
      return const <WearLog>[];
    }

    return ref
        .watch(wearLogRepositoryProvider)
        .fetchGarmentHistory(memberId: selectedMember.id, garmentId: garmentId);
  },
);

final recentWearActivityProvider = FutureProvider<List<WearLog>>((
  Ref ref,
) async {
  final FamilyMember? selectedMember = ref.watch(selectedFamilyMemberProvider);

  if (selectedMember == null) {
    return const <WearLog>[];
  }

  return ref
      .watch(wearLogRepositoryProvider)
      .fetchRecentActivity(memberId: selectedMember.id);
});

final analyticsSummaryProvider = FutureProvider<AnalyticsSummary>((
  Ref ref,
) async {
  final FamilyMember? selectedMember = ref.watch(selectedFamilyMemberProvider);

  if (selectedMember == null) {
    return const AnalyticsSummary(
      totalGarments: 0,
      activeGarments: 0,
      archivedGarments: 0,
      totalWears: 0,
    );
  }

  return ref
      .watch(analyticsRepositoryProvider)
      .fetchSummary(memberId: selectedMember.id);
});

final calendarMonthProvider = FutureProvider.family<List<WearLog>, DateTime>((
  Ref ref,
  DateTime month,
) async {
  final FamilyMember? selectedMember = ref.watch(selectedFamilyMemberProvider);

  if (selectedMember == null) {
    return const <WearLog>[];
  }

  return ref
      .watch(wearLogRepositoryProvider)
      .fetchMonthActivity(memberId: selectedMember.id, month: month);
});

final selectedCalendarDayProvider = StateProvider<DateTime?>((Ref ref) => null);

final selectedDayWearHistoryProvider = FutureProvider<List<WearLog>>((
  Ref ref,
) async {
  final DateTime? selectedDay = ref.watch(selectedCalendarDayProvider);
  final FamilyMember? selectedMember = ref.watch(selectedFamilyMemberProvider);

  if (selectedDay == null || selectedMember == null) {
    return const <WearLog>[];
  }

  return ref
      .watch(wearLogRepositoryProvider)
      .fetchDayHistory(memberId: selectedMember.id, day: selectedDay);
});

final wearLogControllerProvider =
    AutoDisposeAsyncNotifierProvider<WearLogController, void>(
      WearLogController.new,
    );

final outfitMutationControllerProvider =
    AutoDisposeAsyncNotifierProvider<OutfitMutationController, void>(
      OutfitMutationController.new,
    );

final wearOutfitControllerProvider =
    AutoDisposeAsyncNotifierProvider<WearOutfitController, void>(
      WearOutfitController.new,
    );
final garmentArchiveControllerProvider =
    AutoDisposeAsyncNotifierProvider<GarmentArchiveController, void>(
      GarmentArchiveController.new,
    );

final garmentLocationControllerProvider =
    AutoDisposeAsyncNotifierProvider<GarmentLocationController, void>(
      GarmentLocationController.new,
    );

final lendingControllerProvider =
    AutoDisposeAsyncNotifierProvider<LendingController, void>(
      LendingController.new,
    );

class WearLogController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> markAsWorn(
    String garmentId, {
    DateTime? wornDate,
    String? eventName,
    String? notes,
    LaundryStatus? laundryStatusAfter,
  }) async {
    final FamilyMember? selectedMember = ref.read(selectedFamilyMemberProvider);

    if (selectedMember == null) {
      state = AsyncError<void>(
        StateError('No profile selected.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading<void>();

    state = await AsyncValue.guard(
      () => ref
          .read(wearLogRepositoryProvider)
          .createWearLog(
            memberId: selectedMember.id,
            garmentId: garmentId,
            wornDate: wornDate,
            eventName: eventName,
            laundryStatusAfter: laundryStatusAfter,
            notes: notes,
          ),
    );

    if (!state.hasError) {
      _invalidateAfterWearChange(garmentId);
    }
  }

  Future<void> deleteWear({
    required String garmentId,
    required String wearLogId,
  }) async {
    final FamilyMember? selectedMember = ref.read(selectedFamilyMemberProvider);

    if (selectedMember == null) {
      state = AsyncError<void>(
        StateError('No profile selected.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading<void>();

    state = await AsyncValue.guard(
      () => ref
          .read(wearLogRepositoryProvider)
          .deleteWearLog(
            memberId: selectedMember.id,
            garmentId: garmentId,
            wearLogId: wearLogId,
          ),
    );

    if (!state.hasError) {
      _invalidateAfterWearChange(garmentId);
    }
  }

  void _invalidateAfterWearChange(String garmentId) {
    ref.invalidate(garmentWearHistoryProvider(garmentId));
    ref.invalidate(garmentProvider(garmentId));
    ref.invalidate(garmentsProvider);
    ref.invalidate(recentWearActivityProvider);
    ref.invalidate(calendarMonthProvider);
    ref.invalidate(selectedDayWearHistoryProvider);
    ref.invalidate(analyticsSummaryProvider);
    ref.invalidate(alerts.alertsProvider);
  }
}

class GarmentArchiveController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> archive({required String garmentId}) async {
    final FamilyMember? selectedMember = ref.read(selectedFamilyMemberProvider);

    if (selectedMember == null) {
      state = AsyncError<void>(
        StateError('No profile selected.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading<void>();

    state = await AsyncValue.guard(
      () => ref
          .read(garmentRepositoryProvider)
          .archiveGarment(garmentId: garmentId, memberId: selectedMember.id),
    );

    if (!state.hasError) {
      _refreshGarmentLists(garmentId);
    }
  }

  Future<void> restore({required String garmentId}) async {
    final FamilyMember? selectedMember = ref.read(selectedFamilyMemberProvider);

    if (selectedMember == null) {
      state = AsyncError<void>(
        StateError('No profile selected.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading<void>();

    state = await AsyncValue.guard(
      () => ref
          .read(garmentRepositoryProvider)
          .restoreGarment(garmentId: garmentId, memberId: selectedMember.id),
    );

    if (!state.hasError) {
      _refreshGarmentLists(garmentId);
    }
  }

  void _refreshGarmentLists(String garmentId) {
    ref.invalidate(garmentsProvider);
    ref.invalidate(archivedGarmentsProvider);
    ref.invalidate(analyticsSummaryProvider);
    ref.invalidate(garmentProvider(garmentId));
  }
}

class GarmentLocationController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> create({required String name}) async {
    final FamilyMember? selectedMember = ref.read(selectedFamilyMemberProvider);

    if (selectedMember == null) {
      state = AsyncError<void>(
        StateError('No profile selected.'),
        StackTrace.current,
      );
      return;
    }

    if (hasDuplicateLocationName(_currentLocations(), name)) {
      state = AsyncError<void>(
        LocationNameConflict(name.trim()),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading<void>();

    state = await AsyncValue.guard<void>(
      () async {
        try {
          await ref
              .read(garmentLocationRepositoryProvider)
              .createLocation(memberId: selectedMember.id, name: name);
        } on PostgrestException catch (error) {
          if (error.code == '23505') {
            throw LocationNameConflict(name.trim());
          }
          rethrow;
        }
      },
    );

    if (!state.hasError) {
      ref.invalidate(garmentLocationsProvider);
    }
  }

  Future<void> rename({
    required String locationId,
    required String name,
  }) async {
    final FamilyMember? selectedMember = ref.read(selectedFamilyMemberProvider);

    if (selectedMember == null) {
      state = AsyncError<void>(
        StateError('No profile selected.'),
        StackTrace.current,
      );
      return;
    }

    if (hasDuplicateLocationName(_currentLocations(), name, exceptId: locationId)) {
      state = AsyncError<void>(
        LocationNameConflict(name.trim()),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading<void>();

    state = await AsyncValue.guard<void>(
      () async {
        try {
          await ref.read(garmentLocationRepositoryProvider).renameLocation(
                memberId: selectedMember.id,
                locationId: locationId,
                name: name,
              );
        } on PostgrestException catch (error) {
          if (error.code == '23505') {
            throw LocationNameConflict(name.trim());
          }
          rethrow;
        }
      },
    );

    if (!state.hasError) {
      ref.invalidate(garmentLocationsProvider);
      ref.invalidate(garmentsProvider);
      _invalidateGarmentDetailsAtLocation(locationId);
    }
  }

  List<GarmentLocation> _currentLocations() {
    return ref.read(garmentLocationsProvider).valueOrNull ??
        const <GarmentLocation>[];
  }

  void _invalidateGarmentDetailsAtLocation(String locationId) {
    final Set<String> ids = <String>{
      for (final Garment garment
          in ref.read(garmentsProvider).valueOrNull ??
              const <Garment>[])
        if (garment.locationId == locationId) garment.id,
      for (final Garment garment
          in ref.read(archivedGarmentsProvider).valueOrNull ??
              const <Garment>[])
        if (garment.locationId == locationId) garment.id,
    };

    for (final String id in ids) {
      ref.invalidate(garmentProvider(id));
    }
  }

  Future<void> delete({required String locationId}) async {
    final FamilyMember? selectedMember = ref.read(selectedFamilyMemberProvider);

    if (selectedMember == null) {
      state = AsyncError<void>(
        StateError('No profile selected.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading<void>();

    state = await AsyncValue.guard(
      () => ref.read(garmentLocationRepositoryProvider).deleteLocation(
            memberId: selectedMember.id,
            locationId: locationId,
          ),
    );

    if (!state.hasError) {
      ref.invalidate(garmentLocationsProvider);
    }
  }
}

class LendingController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> markReturned({required String garmentId}) async {
    final FamilyMember? selectedMember = ref.read(selectedFamilyMemberProvider);

    if (selectedMember == null) {
      state = AsyncError<void>(
        StateError('No profile selected.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading<void>();

    state = await AsyncValue.guard(
      () => ref
          .read(lendingRepositoryProvider)
          .markReturned(memberId: selectedMember.id, garmentId: garmentId),
    );

    if (!state.hasError) {
      ref.invalidate(activeLendingRecordProvider(garmentId));
      ref.invalidate(garmentProvider(garmentId));
      ref.invalidate(garmentsProvider);
      ref.invalidate(alerts.alertsProvider);
    }
  }
}

class OutfitMutationController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> create({
    required String name,
    required List<String> garmentIds,
    String? coverPhotoUrl,
  }) async {
    final FamilyMember? selectedMember = ref.read(selectedFamilyMemberProvider);

    if (selectedMember == null) {
      state = AsyncError<void>(
        StateError('No profile selected.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading<void>();

    state = await AsyncValue.guard(
      () => ref
          .read(outfitRepositoryProvider)
          .saveOutfit(
            memberId: selectedMember.id,
            name: name,
            garmentIds: garmentIds,
            coverPhotoUrl: coverPhotoUrl,
          ),
    );

    if (!state.hasError) {
      ref.invalidate(outfitsProvider);
    }
  }

  Future<void> updateOutfit({
    required Outfit outfit,
    required String name,
    required List<String> garmentIds,
  }) async {
    final FamilyMember? selectedMember = ref.read(selectedFamilyMemberProvider);

    if (selectedMember == null) {
      state = AsyncError<void>(
        StateError('No profile selected.'),
        StackTrace.current,
      );
      return;
    }

    if (outfit.memberId != selectedMember.id) {
      state = AsyncError<void>(
        StateError('This outfit does not belong to the selected profile.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading<void>();

    state = await AsyncValue.guard(
      () => ref
          .read(outfitRepositoryProvider)
          .updateOutfit(outfit, name: name, garmentIds: garmentIds),
    );

    if (!state.hasError) {
      ref.invalidate(outfitsProvider);
      ref.invalidate(outfitProvider(outfit.id));
    }
  }

  Future<void> delete(String outfitId) async {
    final FamilyMember? selectedMember = ref.read(selectedFamilyMemberProvider);

    if (selectedMember == null) {
      state = AsyncError<void>(
        StateError('No profile selected.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading<void>();

    state = await AsyncValue.guard(
      () => ref
          .read(outfitRepositoryProvider)
          .deleteOutfit(outfitId: outfitId, memberId: selectedMember.id),
    );

    if (!state.hasError) {
      ref.invalidate(outfitsProvider);
      ref.invalidate(outfitProvider(outfitId));
    }
  }
}

class WearOutfitController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> wearOutfit(Outfit outfit) async {
    final FamilyMember? selectedMember = ref.read(selectedFamilyMemberProvider);

    if (selectedMember == null) {
      state = AsyncError<void>(
        StateError('No profile selected.'),
        StackTrace.current,
      );
      return;
    }

    if (outfit.memberId != selectedMember.id) {
      state = AsyncError<void>(
        StateError('This outfit does not belong to the selected profile.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading<void>();

    state = await AsyncValue.guard(() async {
      await ref
          .read(wearLogRepositoryProvider)
          .wearOutfitAtomically(
        memberId: selectedMember.id,
        outfitId: outfit.id,
        laundryStatusAfter: null,
      );
    });

    if (!state.hasError) {
      ref.invalidate(outfitsProvider);
      ref.invalidate(outfitProvider(outfit.id));
      ref.invalidate(recentWearActivityProvider);
      ref.invalidate(calendarMonthProvider);
      ref.invalidate(selectedDayWearHistoryProvider);
      ref.invalidate(analyticsSummaryProvider);
      ref.invalidate(garmentsProvider);
      ref.invalidate(alerts.alertsProvider);

      for (final String garmentId in outfit.garmentIds) {
        ref.invalidate(garmentWearHistoryProvider(garmentId));
        ref.invalidate(garmentProvider(garmentId));
      }
    }
  }
}

final familyMutationControllerProvider =
    AutoDisposeAsyncNotifierProvider<FamilyMutationController, void>(
      FamilyMutationController.new,
    );

class FamilyMutationController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> addMember({
    required String name,
    required String relationship,
    DateTime? birthDate,
    double? heightCm,
    double? weightKg,
    String? currentSize,
  }) async {
    state = const AsyncLoading<void>();

    state = await AsyncValue.guard(
      () => ref
          .read(familyRepositoryProvider)
          .addFamilyMember(
            name: name,
            relationship: relationship,
            birthDate: birthDate,
            heightCm: heightCm,
            weightKg: weightKg,
            currentSize: currentSize,
          ),
    );
  }
}
