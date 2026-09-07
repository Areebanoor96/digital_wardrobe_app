import 'package:digital_wardrobe_app/data/models/garment.dart';

class CategoryMatcher {
  const CategoryMatcher();

  bool areCompatible(GarmentCategory first, GarmentCategory second) {
    // Two garments from the same main category generally
    // should not fill the same outfit role.
    if (first == second) {
      return false;
    }

    return switch (first) {
      GarmentCategory.top => _matchesTop(second),
      GarmentCategory.bottom => _matchesBottom(second),
      GarmentCategory.dress => _matchesDress(second),
      GarmentCategory.outerwear => _matchesOuterwear(second),
      GarmentCategory.shoe => _matchesShoe(second),
      GarmentCategory.accessory => _matchesAccessory(second),
      GarmentCategory.jewelry => _matchesAccessory(second),
      GarmentCategory.bag => _matchesAccessory(second),
      GarmentCategory.activewear => _matchesAccessory(second),
      GarmentCategory.sleepwear => _matchesAccessory(second),
      GarmentCategory.watches => _matchesAccessory(second),
      GarmentCategory.other => _matchesAccessory(second),
    };
  }

  bool _matchesTop(GarmentCategory other) {
    return other == GarmentCategory.bottom ||
        other == GarmentCategory.outerwear ||
        other == GarmentCategory.shoe ||
        other == GarmentCategory.accessory ||
        other == GarmentCategory.jewelry ||
        other == GarmentCategory.bag ||
        other == GarmentCategory.activewear ||
        other == GarmentCategory.sleepwear ||
        other == GarmentCategory.watches ||
        other == GarmentCategory.other;
  }

  bool _matchesBottom(GarmentCategory other) {
    return other == GarmentCategory.top ||
        other == GarmentCategory.outerwear ||
        other == GarmentCategory.shoe ||
        other == GarmentCategory.accessory ||
        other == GarmentCategory.jewelry ||
        other == GarmentCategory.bag ||
        other == GarmentCategory.activewear ||
        other == GarmentCategory.sleepwear ||
        other == GarmentCategory.watches ||
        other == GarmentCategory.other;
  }

  bool _matchesDress(GarmentCategory other) {
    return other == GarmentCategory.outerwear ||
        other == GarmentCategory.shoe ||
        other == GarmentCategory.accessory ||
        other == GarmentCategory.jewelry ||
        other == GarmentCategory.bag ||
        other == GarmentCategory.activewear ||
        other == GarmentCategory.sleepwear ||
        other == GarmentCategory.watches ||
        other == GarmentCategory.other;
  }

  bool _matchesOuterwear(GarmentCategory other) {
    return other == GarmentCategory.top ||
        other == GarmentCategory.bottom ||
        other == GarmentCategory.dress ||
        other == GarmentCategory.shoe ||
        other == GarmentCategory.accessory ||
        other == GarmentCategory.jewelry ||
        other == GarmentCategory.bag ||
        other == GarmentCategory.activewear ||
        other == GarmentCategory.sleepwear ||
        other == GarmentCategory.watches ||
        other == GarmentCategory.other;
  }

  bool _matchesShoe(GarmentCategory other) {
    return other != GarmentCategory.shoe;
  }

  bool _matchesAccessory(GarmentCategory other) {
    return other != GarmentCategory.accessory &&
        other != GarmentCategory.jewelry &&
        other != GarmentCategory.bag &&
        other != GarmentCategory.watches;
  }
}
