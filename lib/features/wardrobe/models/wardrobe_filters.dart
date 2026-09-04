import 'package:digital_wardrobe_app/data/models/garment.dart';

enum WardrobeSortOption {
  newestAdded,
  oldestAdded,
  mostWorn,
  leastWorn,
  recentlyWorn,
  leastRecentlyWorn,
  priceHighToLow,
  priceLowToHigh,
  purchaseNewest,
  purchaseOldest,
  nameAZ,
  nameZA;

  String get label => switch (this) {
    WardrobeSortOption.newestAdded => 'Newest Added',
    WardrobeSortOption.oldestAdded => 'Oldest Added',
    WardrobeSortOption.mostWorn => 'Most Worn',
    WardrobeSortOption.leastWorn => 'Least Worn',
    WardrobeSortOption.recentlyWorn => 'Recently Worn',
    WardrobeSortOption.leastRecentlyWorn => 'Least Recently Worn',
    WardrobeSortOption.priceHighToLow => 'Price: High To Low',
    WardrobeSortOption.priceLowToHigh => 'Price: Low To High',
    WardrobeSortOption.purchaseNewest => 'Purchase Date: Newest',
    WardrobeSortOption.purchaseOldest => 'Purchase Date: Oldest',
    WardrobeSortOption.nameAZ => 'Name: A-Z',
    WardrobeSortOption.nameZA => 'Name: Z-A',
  };
}

class WardrobeFilters {
  const WardrobeFilters({
    this.searchQuery = '',
    this.category,
    this.color,
    this.brand,
    this.size,
    this.occasion,
    this.season,
    this.mood,
    this.laundryStatus,
    this.availabilityStatus,
    this.locationId,
    this.locationName,
    this.stitchingStatus,
    this.ironingStatus,
    this.outerwearSubcategory,
    this.sortOption = WardrobeSortOption.leastWorn,
  });

  final String searchQuery;
  final GarmentCategory? category;
  final String? color;
  final String? brand;
  final String? size;
  final String? occasion;
  final String? season;
  final String? mood;
  final LaundryStatus? laundryStatus;
  final GarmentAvailabilityStatus? availabilityStatus;
  final String? locationId;
  final String? locationName;
  final StitchingStatus? stitchingStatus;
  final IroningStatus? ironingStatus;
  final String? outerwearSubcategory;
  final WardrobeSortOption sortOption;

  int get activeFilterCount {
    int count = 0;

    if (color != null) count++;
    if (brand != null) count++;
    if (size != null) count++;
    if (occasion != null) count++;
    if (season != null) count++;
    if (mood != null) count++;
    if (laundryStatus != null) count++;
    if (availabilityStatus != null) count++;
    if (locationId != null) count++;
    if (stitchingStatus != null) count++;
    if (ironingStatus != null) count++;
    if (outerwearSubcategory != null) count++;

    return count;
  }

  bool get hasActiveFilters =>
      searchQuery.trim().isNotEmpty || activeFilterCount > 0;

  WardrobeFilters copyWith({
    String? searchQuery,
    GarmentCategory? category,
    String? color,
    String? brand,
    String? size,
    String? occasion,
    String? season,
    String? mood,
    LaundryStatus? laundryStatus,
    GarmentAvailabilityStatus? availabilityStatus,
    String? locationId,
    String? locationName,
    StitchingStatus? stitchingStatus,
    IroningStatus? ironingStatus,
    String? outerwearSubcategory,
    WardrobeSortOption? sortOption,
    bool clearCategory = false,
    bool clearColor = false,
    bool clearBrand = false,
    bool clearSize = false,
    bool clearOccasion = false,
    bool clearSeason = false,
    bool clearMood = false,
    bool clearLaundryStatus = false,
    bool clearAvailabilityStatus = false,
    bool clearLocation = false,
    bool clearStitchingStatus = false,
    bool clearIroningStatus = false,
    bool clearOuterwearSubcategory = false,
  }) {
    return WardrobeFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      category: clearCategory ? null : category ?? this.category,
      color: clearColor ? null : color ?? this.color,
      brand: clearBrand ? null : brand ?? this.brand,
      size: clearSize ? null : size ?? this.size,
      occasion: clearOccasion ? null : occasion ?? this.occasion,
      season: clearSeason ? null : season ?? this.season,
      mood: clearMood ? null : mood ?? this.mood,
      laundryStatus: clearLaundryStatus
          ? null
          : laundryStatus ?? this.laundryStatus,
      availabilityStatus: clearAvailabilityStatus
          ? null
          : availabilityStatus ?? this.availabilityStatus,
      locationId: clearLocation ? null : locationId ?? this.locationId,
      locationName: clearLocation ? null : locationName ?? this.locationName,
      stitchingStatus: clearStitchingStatus
          ? null
          : stitchingStatus ?? this.stitchingStatus,
      ironingStatus: clearIroningStatus
          ? null
          : ironingStatus ?? this.ironingStatus,
      outerwearSubcategory: clearOuterwearSubcategory
          ? null
          : outerwearSubcategory ?? this.outerwearSubcategory,
      sortOption: sortOption ?? this.sortOption,
    );
  }
}
