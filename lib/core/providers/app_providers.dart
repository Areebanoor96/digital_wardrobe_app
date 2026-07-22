import 'dart:async';

import 'package:digital_wardrobe_app/core/services/image_service.dart';
import 'package:digital_wardrobe_app/core/services/supabase_service.dart';
import 'package:digital_wardrobe_app/data/models/analytics.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';

import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/outfit.dart';
import 'package:digital_wardrobe_app/data/models/profile.dart';
import 'package:digital_wardrobe_app/data/models/wear_log.dart';
import 'package:digital_wardrobe_app/data/repositories/alerts_repository.dart';
import 'package:digital_wardrobe_app/data/repositories/analytics_repository.dart';
import 'package:digital_wardrobe_app/data/repositories/family_repository.dart';
import 'package:digital_wardrobe_app/data/repositories/garment_repository.dart';
import 'package:digital_wardrobe_app/data/repositories/outfit_repository.dart';
import 'package:digital_wardrobe_app/data/repositories/profile_repository.dart';
import 'package:digital_wardrobe_app/data/repositories/wear_log_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';


final Provider<ImageService> imageServiceProvider = Provider<ImageService>(
  (Ref ref) => ImageService(ImagePicker()),
);

final Provider<GarmentRepository> garmentRepositoryProvider =
    Provider<GarmentRepository>(
      (Ref ref) => GarmentRepository(SupabaseService.client),
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
final Provider<FamilyRepository> familyRepositoryProvider =
    Provider<FamilyRepository>(
      (Ref ref) => FamilyRepository(SupabaseService.client),
    );
final Provider<WearLogRepository> wearLogRepositoryProvider =
    Provider<WearLogRepository>(
      (Ref ref) => WearLogRepository(SupabaseService.client),
    );
final Provider<AlertsRepository> alertsRepositoryProvider =
    Provider<AlertsRepository>(
      (Ref ref) => AlertsRepository(SupabaseService.client),
    );
final FutureProvider<List<Garment>> garmentsProvider =
    FutureProvider<List<Garment>>(
      (Ref ref) => ref.watch(garmentRepositoryProvider).fetchGarments(),
    );
final garmentProvider = FutureProvider.family<Garment, String>(
  (Ref ref, String id) => ref.watch(garmentRepositoryProvider).fetchGarment(id),
);
final FutureProvider<List<Outfit>> outfitsProvider =
    FutureProvider<List<Outfit>>(
      (Ref ref) => ref.watch(outfitRepositoryProvider).fetchOutfits(),
    );
final outfitProvider = FutureProvider.family<Outfit, String>(
  (Ref ref, String outfitId) =>
      ref.watch(outfitRepositoryProvider).fetchOutfit(outfitId),
);
final FutureProvider<Profile> profileProvider = FutureProvider<Profile>(
  (Ref ref) => ref.watch(profileRepositoryProvider).fetchProfile(),
);
final FutureProvider<List<FamilyMember>> familyMembersProvider =
    FutureProvider<List<FamilyMember>>(
      (Ref ref) => ref.watch(familyRepositoryProvider).fetchFamilyMembers(),
    );
final garmentWearHistoryProvider = FutureProvider.family<List<WearLog>, String>(
  (Ref ref, String garmentId) =>
      ref.watch(wearLogRepositoryProvider).fetchGarmentHistory(garmentId),
);
final recentWearActivityProvider = FutureProvider<List<WearLog>>(
  (Ref ref) => ref.watch(wearLogRepositoryProvider).fetchRecentActivity(),
);
final analyticsSummaryProvider = FutureProvider<AnalyticsSummary>(
  (Ref ref) => ref.watch(analyticsRepositoryProvider).fetchSummary(),
);
final costPerWearProvider = FutureProvider<List<CostPerWearEntry>>(
  (Ref ref) => ref.watch(analyticsRepositoryProvider).fetchCostPerWear(),
);
final calendarMonthProvider = FutureProvider.family<List<WearLog>, DateTime>(
  (Ref ref, DateTime month) =>
      ref.watch(wearLogRepositoryProvider).fetchMonthActivity(month),
);
final selectedCalendarDayProvider = StateProvider<DateTime?>((Ref ref) => null);
final selectedDayWearHistoryProvider = FutureProvider<List<WearLog>>((Ref ref) {
  final DateTime? selectedDay = ref.watch(selectedCalendarDayProvider);
  if (selectedDay == null) {
    return Future<List<WearLog>>.value(const <WearLog>[]);
  }
  return ref.watch(wearLogRepositoryProvider).fetchDayHistory(selectedDay);
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

class WearLogController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> markAsWorn(String garmentId) async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(
      () => ref.read(wearLogRepositoryProvider).createWearLog(garmentId),
    );
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
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(
      () => ref
          .read(outfitRepositoryProvider)
          .saveOutfit(
            name: name,
            garmentIds: garmentIds,
            coverPhotoUrl: coverPhotoUrl,
          ),
    );
  }

  Future<void> updateOutfit({
    required Outfit outfit,
    required String name,
    required List<String> garmentIds,
  }) async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(
      () => ref
          .read(outfitRepositoryProvider)
          .updateOutfit(outfit, name: name, garmentIds: garmentIds),
    );
  }

  Future<void> delete(String outfitId) async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(
      () => ref.read(outfitRepositoryProvider).deleteOutfit(outfitId),
    );
  }
}

class WearOutfitController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> wearOutfit(Outfit outfit) async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(() async {
      await ref
          .read(wearLogRepositoryProvider)
          .createWearLogsForOutfit(
            outfitId: outfit.id,
            garmentIds: outfit.garmentIds,
          );
      await ref.read(outfitRepositoryProvider).incrementWearCount(outfit);
    });
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
