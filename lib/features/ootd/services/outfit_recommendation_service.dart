import 'package:digital_wardrobe_app/features/outfits/models/outfit_context.dart';
import 'package:digital_wardrobe_app/features/outfits/services/outfit_intelligence_engine.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';

class OutfitRecommendation {
  const OutfitRecommendation({
    required this.garments,
    required this.reason,
    this.score = 0,
    this.heroGarment,
    this.reasons = const <String>[],
  });

  final List<Garment> garments;
  final String reason;

  final int score;
  final Garment? heroGarment;
  final List<String> reasons;
}

class OutfitRecommendationService {
  const OutfitRecommendationService({
    this.engine = const OutfitIntelligenceEngine(),
  });

  final OutfitIntelligenceEngine engine;

  OutfitRecommendation recommend({
    required List<Garment> allGarments,
    required Set<String> recentlyWornGarmentIds,
    OutfitContext context = const OutfitContext(),
  }) {
    final List<Garment> eligible = allGarments
        .where(
          (Garment garment) =>
      !garment.isArchived &&
          garment.laundryStatus == LaundryStatus.clean,
    )
        .toList();

    if (eligible.isEmpty) {
      return const OutfitRecommendation(
        garments: <Garment>[],
        reason:
        'Add some clean garments to your wardrobe to get a recommendation.',
      );
    }

    final Garment hero = _chooseHero(
      garments: eligible,
      recentlyWornGarmentIds: recentlyWornGarmentIds,
      context: context,
    );

    final OutfitContext ootdContext = context.copyWith(
      heroGarment: hero,
    );

    final recommendation = engine.recommend(
      garments: eligible,
      context: ootdContext,
    );

    if (recommendation.garments.isEmpty) {
      return OutfitRecommendation(
        garments: <Garment>[hero],
        reason: 'Start today\'s outfit with ${hero.name}.',
      );
    }

    return OutfitRecommendation(
      garments: recommendation.garments,
      reason: _buildReason(
        hero: hero,
        score: recommendation.score,
        reasons: recommendation.reasons,
      ),
      score: recommendation.score,
      heroGarment: hero,
      reasons: recommendation.reasons,
    );
  }

  Garment _chooseHero({
    required List<Garment> garments,
    required Set<String> recentlyWornGarmentIds,
    required OutfitContext context,
  }) {
    final List<Garment> ranked = List<Garment>.from(garments);

    ranked.sort((Garment a, Garment b) {
      final int aScore = _heroScore(
        a,
        recentlyWornGarmentIds: recentlyWornGarmentIds,
        context: context,
      );

      final int bScore = _heroScore(
        b,
        recentlyWornGarmentIds: recentlyWornGarmentIds,
        context: context,
      );

      return bScore.compareTo(aScore);
    });

    return ranked.first;
  }

  int _heroScore(
      Garment garment, {
        required Set<String> recentlyWornGarmentIds,
        required OutfitContext context,
      }) {
    int score = 0;

    if (!recentlyWornGarmentIds.contains(garment.id)) {
      score += 20;
    }

    if (garment.lastWornDate == null) {
      score += 20;
    } else {
      final int daysSinceWorn = DateTime.now()
          .difference(garment.lastWornDate!)
          .inDays;

      if (daysSinceWorn >= 30) {
        score += 20;
      } else if (daysSinceWorn >= 14) {
        score += 15;
      } else if (daysSinceWorn >= 7) {
        score += 10;
      }
    }

    if (_containsIgnoreCase(
      garment.occasions,
      context.occasion,
    )) {
      score += 25;
    }

    if (_containsIgnoreCase(
      garment.seasons,
      context.season,
    )) {
      score += 20;
    }

    if (_containsIgnoreCase(
      garment.moods,
      context.mood,
    )) {
      score += 15;
    }

    return score;
  }

  bool _containsIgnoreCase(
      List<String> values,
      String? target,
      ) {
    if (target == null) {
      return false;
    }

    final String normalizedTarget = target.toLowerCase();

    return values.any(
          (String value) =>
      value.toLowerCase() == normalizedTarget,
    );
  }

  String _buildReason({
    required Garment hero,
    required int score,
    required List<String> reasons,
  }) {
    final StringBuffer buffer = StringBuffer(
      '${hero.name} is today\'s hero piece. $score% match.',
    );

    if (reasons.isNotEmpty) {
      buffer.write(' ${reasons.take(2).join('. ')}.');
    }

    return buffer.toString();
  }
}