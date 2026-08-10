import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/outfits/models/outfit_context.dart';
import 'package:digital_wardrobe_app/features/outfits/models/outfit_score.dart';
import 'package:digital_wardrobe_app/features/outfits/services/category_matcher.dart';
import 'package:digital_wardrobe_app/features/outfits/services/color_matcher.dart';

class OutfitScorer {
  const OutfitScorer({
    this.categoryMatcher = const CategoryMatcher(),
    this.colorMatcher = const ColorMatcher(),
  });

  final CategoryMatcher categoryMatcher;
  final ColorMatcher colorMatcher;

  OutfitScore scoreGarment({
    required Garment candidate,
    required OutfitContext context,
  }) {
    int occasionScore = 0;
    int seasonScore = 0;
    int moodScore = 0;
    int categoryScore = 0;
    int colorScore = 0;
    int freshnessScore = 0;

    final List<String> reasons = <String>[];

    final Garment? hero = context.heroGarment;

    // Occasion: max 25
    if (context.occasion != null &&
        candidate.occasions.any(
              (String value) =>
          value.toLowerCase() == context.occasion!.toLowerCase(),
        )) {
      occasionScore = 25;
      reasons.add('Matches ${context.occasion} occasion');
    }

    // Season: max 20
    if (context.season != null &&
        candidate.seasons.any(
              (String value) =>
          value.toLowerCase() == context.season!.toLowerCase(),
        )) {
      seasonScore = 20;
      reasons.add('Suitable for ${context.season}');
    }

    // Mood: max 20
    if (context.mood != null &&
        candidate.moods.any(
              (String value) =>
          value.toLowerCase() == context.mood!.toLowerCase(),
        )) {
      moodScore = 20;
      reasons.add('Matches ${context.mood} mood');
    }

    // Category: max 15
    if (hero != null &&
        categoryMatcher.areCompatible(
          hero.category,
          candidate.category,
        )) {
      categoryScore = 15;
      reasons.add('Complements the hero piece');
    }

    // Color: max 10
    if (hero != null) {
      colorScore = colorMatcher.score(hero, candidate);

      if (colorScore >= 8) {
        reasons.add('Strong color compatibility');
      }
    }

    // Freshness: max 10
    freshnessScore = _freshnessScore(candidate);

    if (freshnessScore >= 8) {
      reasons.add('Has not been worn recently');
    }

    final int total = (
        occasionScore +
            seasonScore +
            moodScore +
            categoryScore +
            colorScore +
            freshnessScore
    ).clamp(0, 100);

    return OutfitScore(
      total: total,
      occasionScore: occasionScore,
      seasonScore: seasonScore,
      moodScore: moodScore,
      categoryScore: categoryScore,
      colorScore: colorScore,
      freshnessScore: freshnessScore,
      reasons: reasons,
    );
  }

  int _freshnessScore(Garment garment) {
    final DateTime? lastWorn = garment.lastWornDate;

    if (lastWorn == null) {
      return 10;
    }

    final int daysSinceWorn = DateTime.now()
        .difference(lastWorn)
        .inDays;

    if (daysSinceWorn >= 30) {
      return 10;
    }

    if (daysSinceWorn >= 14) {
      return 8;
    }

    if (daysSinceWorn >= 7) {
      return 5;
    }

    if (daysSinceWorn >= 3) {
      return 3;
    }

    return 0;
  }
}