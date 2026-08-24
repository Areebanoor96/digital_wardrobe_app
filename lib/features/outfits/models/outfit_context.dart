import 'package:digital_wardrobe_app/data/models/garment.dart';

class OutfitContext {
  const OutfitContext({
    this.heroGarment,
    this.occasion,
    this.season,
    this.mood,
    this.dressCode,
    this.expectedActivityLevel,
    this.indoor,
    this.outdoor,
    this.requireCleanGarments = true,
  });

  final Garment? heroGarment;
  final String? occasion;
  final String? season;
  final String? mood;
  final String? dressCode;
  final int? expectedActivityLevel;
  final bool? indoor;
  final bool? outdoor;
  final bool requireCleanGarments;

  OutfitContext copyWith({
    Garment? heroGarment,
    String? occasion,
    String? season,
    String? mood,
    String? dressCode,
    int? expectedActivityLevel,
    bool? indoor,
    bool? outdoor,
    bool? requireCleanGarments,
    bool clearHeroGarment = false,
    bool clearOccasion = false,
    bool clearSeason = false,
    bool clearMood = false,
    bool clearDressCode = false,
    bool clearExpectedActivityLevel = false,
    bool clearIndoor = false,
    bool clearOutdoor = false,
  }) {
    return OutfitContext(
      heroGarment: clearHeroGarment ? null : heroGarment ?? this.heroGarment,
      occasion: clearOccasion ? null : occasion ?? this.occasion,
      season: clearSeason ? null : season ?? this.season,
      mood: clearMood ? null : mood ?? this.mood,
      dressCode: clearDressCode ? null : dressCode ?? this.dressCode,
      expectedActivityLevel: clearExpectedActivityLevel
          ? null
          : expectedActivityLevel ?? this.expectedActivityLevel,
      indoor: clearIndoor ? null : indoor ?? this.indoor,
      outdoor: clearOutdoor ? null : outdoor ?? this.outdoor,
      requireCleanGarments: requireCleanGarments ?? this.requireCleanGarments,
    );
  }
}
