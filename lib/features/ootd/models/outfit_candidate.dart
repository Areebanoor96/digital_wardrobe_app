import 'package:digital_wardrobe_app/data/models/garment.dart';

enum OotdTemplateType { separated, dress }

class OutfitCandidate {
  const OutfitCandidate({required this.templateType, required this.garments});

  final OotdTemplateType templateType;
  final List<Garment> garments;

  List<String> get garmentIds =>
      garments.map((Garment garment) => garment.id).toList();

  bool containsCategory(GarmentCategory category) {
    return garments.any((Garment garment) => garment.category == category);
  }

  List<Garment> garmentsIn(GarmentCategory category) {
    return garments
        .where((Garment garment) => garment.category == category)
        .toList();
  }
}
