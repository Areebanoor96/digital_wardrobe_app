import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/wardrobe/models/wardrobe_filters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final StateNotifierProvider<WardrobeFilterNotifier, WardrobeFilters>
wardrobeFilterProvider =
    StateNotifierProvider<WardrobeFilterNotifier, WardrobeFilters>(
      (Ref ref) => WardrobeFilterNotifier(),
    );

final Provider<List<Garment>> filteredGarmentsProvider =
    Provider<List<Garment>>((Ref ref) {
      final List<Garment> garments =
          ref.watch(garmentsProvider).valueOrNull ?? const <Garment>[];

      final WardrobeFilters filters = ref.watch(wardrobeFilterProvider);

      final List<Garment> filtered = garments.where((Garment garment) {
        final String query = filters.searchQuery.trim().toLowerCase();

        final String searchableText = <String>[
          garment.name,
          garment.category.label,
          garment.subcategory ?? '',
          garment.brand ?? '',
          garment.colorName ?? '',
          ...garment.colorNames,
          garment.size ?? '',
          ...garment.effectiveSizes,
          garment.purchaseStore ?? '',
          garment.locationName ?? '',
          garment.availabilityStatus.label,
          garment.stitchingStatus?.label ?? '',
          garment.ironingStatus?.label ?? '',
          garment.fabric ?? '',
          garment.washInstructions ?? '',
          ...garment.occasions,
          ...garment.seasons,
          ...garment.moods,
        ].join(' ').toLowerCase();

        final bool matchesSearch =
            query.isEmpty || searchableText.contains(query);

        final bool matchesCategory =
            filters.category == null || garment.category == filters.category;

        final bool matchesColor =
            filters.color == null ||
            garment.colorNames.contains(filters.color!.toLowerCase());

        final bool matchesBrand =
            filters.brand == null ||
            garment.brand?.toLowerCase() == filters.brand!.toLowerCase();

        final bool matchesSize =
            filters.size == null ||
            garment.effectiveSizes.any(
              (String value) =>
                  value.toLowerCase() == filters.size!.toLowerCase(),
            );

        final bool matchesOccasion =
            filters.occasion == null ||
            garment.occasions.any(
              (String value) =>
                  value.toLowerCase() == filters.occasion!.toLowerCase(),
            );

        final bool matchesSeason =
            filters.season == null ||
            garment.seasons.any(
              (String value) =>
                  value.toLowerCase() == filters.season!.toLowerCase(),
            );

        final bool matchesMood =
            filters.mood == null ||
            garment.moods.any(
              (String value) =>
                  value.toLowerCase() == filters.mood!.toLowerCase(),
            );

        final bool matchesLaundry =
            filters.laundryStatus == null ||
            garment.laundryStatus == filters.laundryStatus;
        final bool matchesAvailability =
            filters.availabilityStatus == null ||
            garment.availabilityStatus == filters.availabilityStatus;
        final bool matchesLocation =
            filters.locationId == null ||
            garment.locationId == filters.locationId;
        final bool matchesStitching =
            filters.stitchingStatus == null ||
            garment.stitchingStatus == filters.stitchingStatus;
        final bool matchesIroning =
            filters.ironingStatus == null ||
            garment.ironingStatus == filters.ironingStatus;
        final bool matchesOuterwearSubcategory =
            filters.outerwearSubcategory == null ||
            (garment.category == GarmentCategory.outerwear &&
                garment.subcategory?.toLowerCase() ==
                    filters.outerwearSubcategory!.toLowerCase());

        return matchesSearch &&
            matchesCategory &&
            matchesColor &&
            matchesBrand &&
            matchesSize &&
            matchesOccasion &&
            matchesSeason &&
            matchesMood &&
            matchesLaundry &&
            matchesAvailability &&
            matchesLocation &&
            matchesStitching &&
            matchesIroning &&
            matchesOuterwearSubcategory;
      }).toList();

      _sortGarments(filtered, filters.sortOption);

      return filtered;
    });

class WardrobeFilterNotifier extends StateNotifier<WardrobeFilters> {
  WardrobeFilterNotifier() : super(const WardrobeFilters());

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value);
  }

  void setCategory(GarmentCategory? value) {
    state = value == null
        ? state.copyWith(clearCategory: true)
        : state.copyWith(category: value);
  }

  void setColor(String? value) {
    state = value == null
        ? state.copyWith(clearColor: true)
        : state.copyWith(color: value);
  }

  void setBrand(String? value) {
    state = value == null
        ? state.copyWith(clearBrand: true)
        : state.copyWith(brand: value);
  }

  void setSize(String? value) {
    state = value == null
        ? state.copyWith(clearSize: true)
        : state.copyWith(size: value);
  }

  void setOccasion(String? value) {
    state = value == null
        ? state.copyWith(clearOccasion: true)
        : state.copyWith(occasion: value);
  }

  void setSeason(String? value) {
    state = value == null
        ? state.copyWith(clearSeason: true)
        : state.copyWith(season: value);
  }

  void setMood(String? value) {
    state = value == null
        ? state.copyWith(clearMood: true)
        : state.copyWith(mood: value);
  }

  void setLaundryStatus(LaundryStatus? value) {
    state = value == null
        ? state.copyWith(clearLaundryStatus: true)
        : state.copyWith(laundryStatus: value);
  }

  void setAvailabilityStatus(GarmentAvailabilityStatus? value) {
    state = value == null
        ? state.copyWith(clearAvailabilityStatus: true)
        : state.copyWith(availabilityStatus: value);
  }

  void setLocation({String? id, String? name}) {
    state = id == null
        ? state.copyWith(clearLocation: true)
        : state.copyWith(locationId: id, locationName: name);
  }

  void setStitchingStatus(StitchingStatus? value) {
    state = value == null
        ? state.copyWith(clearStitchingStatus: true)
        : state.copyWith(stitchingStatus: value);
  }

  void setIroningStatus(IroningStatus? value) {
    state = value == null
        ? state.copyWith(clearIroningStatus: true)
        : state.copyWith(ironingStatus: value);
  }

  void setOuterwearSubcategory(String? value) {
    state = value == null
        ? state.copyWith(clearOuterwearSubcategory: true)
        : state.copyWith(outerwearSubcategory: value);
  }

  void setSortOption(WardrobeSortOption value) {
    state = state.copyWith(sortOption: value);
  }

  void clearFilters() {
    state = WardrobeFilters(
      searchQuery: state.searchQuery,
    );
  }

  void clearAll() {
    state = const WardrobeFilters();
  }
}

void _sortGarments(List<Garment> garments, WardrobeSortOption option) {
  switch (option) {
    case WardrobeSortOption.newestAdded:
      // The repository already returns newest-created garments first.
      break;

    case WardrobeSortOption.oldestAdded:
      garments.replaceRange(0, garments.length, garments.reversed);

    case WardrobeSortOption.mostWorn:
      garments.sort(
        (Garment a, Garment b) => b.wearCount.compareTo(a.wearCount),
      );

    case WardrobeSortOption.leastWorn:
      garments.sort(
        (Garment a, Garment b) => a.wearCount.compareTo(b.wearCount),
      );

    case WardrobeSortOption.recentlyWorn:
      garments.sort(
        (Garment a, Garment b) {
          if (a.lastWornDate == null && b.lastWornDate == null) return 0;
          if (a.lastWornDate == null) return -1;
          if (b.lastWornDate == null) return 1;
          return b.lastWornDate!.compareTo(a.lastWornDate!);
        },
      );

    case WardrobeSortOption.leastRecentlyWorn:
      garments.sort(
        (Garment a, Garment b) =>
            _compareNullableDates(a.lastWornDate, b.lastWornDate),
      );

    case WardrobeSortOption.priceHighToLow:
      garments.sort(
        (Garment a, Garment b) => (b.price ?? -1).compareTo(a.price ?? -1),
      );

    case WardrobeSortOption.priceLowToHigh:
      garments.sort(
        (Garment a, Garment b) =>
            (a.price ?? double.infinity).compareTo(b.price ?? double.infinity),
      );

    case WardrobeSortOption.purchaseNewest:
      garments.sort(
        (Garment a, Garment b) {
          if (a.purchaseDate == null && b.purchaseDate == null) return 0;
          if (a.purchaseDate == null) return -1;
          if (b.purchaseDate == null) return 1;
          return b.purchaseDate!.compareTo(a.purchaseDate!);
        },
      );

    case WardrobeSortOption.purchaseOldest:
      garments.sort(
        (Garment a, Garment b) =>
            _compareNullableDates(a.purchaseDate, b.purchaseDate),
      );

    case WardrobeSortOption.nameAZ:
      garments.sort(
        (Garment a, Garment b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

    case WardrobeSortOption.nameZA:
      garments.sort(
        (Garment a, Garment b) =>
            b.name.toLowerCase().compareTo(a.name.toLowerCase()),
      );
  }
}

int _compareNullableDates(DateTime? first, DateTime? second) {
  if (first == null && second == null) return 0;
  if (first == null) return 1;
  if (second == null) return -1;

  return first.compareTo(second);
}
