import 'package:digital_wardrobe_app/data/models/garment.dart';

class OutfitContext {
  const OutfitContext({
    this.heroGarment,
    this.occasion,
    this.season,
    this.mood,
    this.requireCleanGarments = true,
  });

  final Garment? heroGarment;
  final String? occasion;
  final String? season;
  final String? mood;
  final bool requireCleanGarments;

  OutfitContext copyWith({
    Garment? heroGarment,
    String? occasion,
    String? season,
    String? mood,
    bool? requireCleanGarments,
    bool clearHeroGarment = false,
    bool clearOccasion = false,
    bool clearSeason = false,
    bool clearMood = false,
  }) {
    return OutfitContext(
      heroGarment: clearHeroGarment
          ? null
          : heroGarment ?? this.heroGarment,
      occasion: clearOccasion ? null : occasion ?? this.occasion,
      season: clearSeason ? null : season ?? this.season,
      mood: clearMood ? null : mood ?? this.mood,
      requireCleanGarments:
      requireCleanGarments ?? this.requireCleanGarments,
    );
  }
}