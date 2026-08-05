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
    WardrobeSortOption.newestAdded => 'Newest added',
    WardrobeSortOption.oldestAdded => 'Oldest added',
    WardrobeSortOption.mostWorn => 'Most worn',
    WardrobeSortOption.leastWorn => 'Least worn',
    WardrobeSortOption.recentlyWorn => 'Recently worn',
    WardrobeSortOption.leastRecentlyWorn => 'Least recently worn',
    WardrobeSortOption.priceHighToLow => 'Price: high to low',
    WardrobeSortOption.priceLowToHigh => 'Price: low to high',
    WardrobeSortOption.purchaseNewest => 'Purchase date: newest',
    WardrobeSortOption.purchaseOldest => 'Purchase date: oldest',
    WardrobeSortOption.nameAZ => 'Name: A–Z',
    WardrobeSortOption.nameZA => 'Name: Z–A',
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
    this.sortOption = WardrobeSortOption.newestAdded,
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
  final WardrobeSortOption sortOption;

  int get activeFilterCount {
    int count = 0;

    if (category != null) count++;
    if (color != null) count++;
    if (brand != null) count++;
    if (size != null) count++;
    if (occasion != null) count++;
    if (season != null) count++;
    if (mood != null) count++;
    if (laundryStatus != null) count++;

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
    WardrobeSortOption? sortOption,
    bool clearCategory = false,
    bool clearColor = false,
    bool clearBrand = false,
    bool clearSize = false,
    bool clearOccasion = false,
    bool clearSeason = false,
    bool clearMood = false,
    bool clearLaundryStatus = false,
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
      sortOption: sortOption ?? this.sortOption,
    );
  }
}
