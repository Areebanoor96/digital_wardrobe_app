import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/ootd/models/outfit_candidate.dart';

class OutfitTemplate {
  const OutfitTemplate({
    required this.type,
    required this.requiredCategories,
    this.optionalCategories = const <GarmentCategory>[],
  });

  final OotdTemplateType type;
  final List<GarmentCategory> requiredCategories;
  final List<GarmentCategory> optionalCategories;

  bool canBuildFrom(List<Garment> garments) {
    return requiredCategories.every(
      (GarmentCategory category) =>
          garments.any((Garment garment) => garment.category == category),
    );
  }
}

class OutfitTemplates {
  const OutfitTemplates();

  static const OutfitTemplate separated = OutfitTemplate(
    type: OotdTemplateType.separated,
    requiredCategories: <GarmentCategory>[
      GarmentCategory.top,
      GarmentCategory.bottom,
      GarmentCategory.shoe,
    ],
    optionalCategories: <GarmentCategory>[
      GarmentCategory.outerwear,
      GarmentCategory.accessory,
      GarmentCategory.jewelry,
      GarmentCategory.bag,
    ],
  );

  static const OutfitTemplate dress = OutfitTemplate(
    type: OotdTemplateType.dress,
    requiredCategories: <GarmentCategory>[
      GarmentCategory.dress,
      GarmentCategory.shoe,
    ],
    optionalCategories: <GarmentCategory>[
      GarmentCategory.outerwear,
      GarmentCategory.accessory,
      GarmentCategory.jewelry,
      GarmentCategory.bag,
    ],
  );

  static const List<OutfitTemplate> all = <OutfitTemplate>[separated, dress];
}
