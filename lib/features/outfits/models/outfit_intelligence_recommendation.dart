import 'package:digital_wardrobe_app/data/models/garment.dart';

class OutfitIntelligenceRecommendation {
  const OutfitIntelligenceRecommendation({
    required this.garments,
    required this.score,
    required this.reasons,
  });

  final List<Garment> garments;
  final int score;
  final List<String> reasons;

  bool get isEmpty => garments.isEmpty;
}
