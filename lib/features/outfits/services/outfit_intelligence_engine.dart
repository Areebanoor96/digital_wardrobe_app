import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/outfits/models/outfit_context.dart';
import 'package:digital_wardrobe_app/features/outfits/models/outfit_intelligence_recommendation.dart';
import 'package:digital_wardrobe_app/features/outfits/models/outfit_score.dart';
import 'package:digital_wardrobe_app/features/outfits/services/outfit_scorer.dart';

class OutfitIntelligenceEngine {
  const OutfitIntelligenceEngine({
    this.scorer = const OutfitScorer(),
  });

  final OutfitScorer scorer;

  OutfitIntelligenceRecommendation recommend({
    required List<Garment> garments,
    required OutfitContext context,
  }) {
    final List<Garment> candidates = _eligibleGarments(
      garments: garments,
      context: context,
    );

    if (candidates.isEmpty) {
      return const OutfitIntelligenceRecommendation(
        garments: <Garment>[],
        score: 0,
        reasons: <String>[
          'No suitable garments are currently available.',
        ],
      );
    }

    final List<_ScoredGarment> ranked = candidates.map((Garment garment) {
      final OutfitScore score = scorer.scoreGarment(
        candidate: garment,
        context: context,
      );

      return _ScoredGarment(
        garment: garment,
        score: score,
      );
    }).toList()
      ..sort(
            (_ScoredGarment a, _ScoredGarment b) =>
            b.score.total.compareTo(a.score.total),
      );

    final List<_ScoredGarment> selected = _buildOutfit(
      ranked,
      context: context,
    );

    final Garment? hero = context.heroGarment;

    final List<Garment> recommendedGarments = <Garment>[
      if (hero != null) hero,
      ...selected.map((_ScoredGarment item) => item.garment),
    ];

    final int overallScore = _calculateOverallScore(selected);

    final List<String> reasons = _collectReasons(
      selected,
      context: context,
    );

    return OutfitIntelligenceRecommendation(
      garments: recommendedGarments,
      score: overallScore,
      reasons: reasons,
    );
  }

  List<Garment> _eligibleGarments({
    required List<Garment> garments,
    required OutfitContext context,
  }) {
    return garments.where((Garment garment) {
      // Never recommend something stored in Closet Vault.
      if (garment.isArchived) {
        return false;
      }

      // Don't recommend the hero garment as a candidate for itself.
      if (garment.id == context.heroGarment?.id) {
        return false;
      }

      // If clean garments are required, reject anything unavailable
      // because of its laundry state.
      if (context.requireCleanGarments &&
          garment.laundryStatus != LaundryStatus.clean) {
        return false;
      }

      return true;
    }).toList();
  }

  List<_ScoredGarment> _buildOutfit(
      List<_ScoredGarment> ranked, {
        required OutfitContext context,
      }) {
    final List<_ScoredGarment> selected = <_ScoredGarment>[];
    final Set<GarmentCategory> usedCategories = <GarmentCategory>{};

    final Garment? hero = context.heroGarment;

    if (hero != null) {
      usedCategories.add(hero.category);
    }

    for (final _ScoredGarment candidate in ranked) {
      if (selected.length >= 5) {
        break;
      }

      if (!_canAddCategory(
        candidate.garment.category,
        usedCategories,
      )) {
        continue;
      }

      selected.add(candidate);
      usedCategories.add(candidate.garment.category);
    }

    return selected;
  }

  bool _canAddCategory(
      GarmentCategory category,
      Set<GarmentCategory> usedCategories,
      ) {
    // Only one garment from each category for the first version
    // of the intelligence engine.
    if (usedCategories.contains(category)) {
      return false;
    }

    // A dress already provides the main body of an outfit,
    // so don't combine it with a separate top or bottom.
    if (usedCategories.contains(GarmentCategory.dress) &&
        (category == GarmentCategory.top ||
            category == GarmentCategory.bottom)) {
      return false;
    }

    // Likewise, don't add a dress after selecting a top or bottom.
    if (category == GarmentCategory.dress &&
        (usedCategories.contains(GarmentCategory.top) ||
            usedCategories.contains(GarmentCategory.bottom))) {
      return false;
    }

    return true;
  }

  int _calculateOverallScore(
      List<_ScoredGarment> selected,
      ) {
    if (selected.isEmpty) {
      return 0;
    }

    final int total = selected.fold<int>(
      0,
          (int sum, _ScoredGarment item) => sum + item.score.total,
    );

    return (total / selected.length).round().clamp(0, 100);
  }

  List<String> _collectReasons(
      List<_ScoredGarment> selected, {
        required OutfitContext context,
      }) {
    final List<String> reasons = <String>[];

    if (context.occasion != null) {
      reasons.add('Built for ${context.occasion}');
    }

    if (context.season != null) {
      reasons.add('Suitable for ${context.season}');
    }

    if (context.mood != null) {
      reasons.add('Matches a ${context.mood} mood');
    }

    for (final _ScoredGarment item in selected) {
      for (final String reason in item.score.reasons) {
        if (!reasons.contains(reason)) {
          reasons.add(reason);
        }
      }
    }

    return reasons.take(5).toList();
  }
  List<Garment> swapCandidates({
    required Garment currentGarment,
    required List<Garment> allGarments,
    required List<Garment> currentOutfit,
    required OutfitContext context,
    int limit = 3,
  }) {
    final Set<String> currentOutfitIds = currentOutfit
        .map((Garment garment) => garment.id)
        .toSet();

    final List<Garment> candidates = allGarments.where((Garment garment) {
      // Don't suggest the garment we're replacing.
      if (garment.id == currentGarment.id) {
        return false;
      }

      // Don't suggest something already in the outfit.
      if (currentOutfitIds.contains(garment.id)) {
        return false;
      }

      // Replacement should perform the same clothing role.
      if (garment.category != currentGarment.category) {
        return false;
      }

      // Never suggest Closet Vault garments.
      if (garment.isArchived) {
        return false;
      }

      // Respect laundry availability.
      if (context.requireCleanGarments &&
          garment.laundryStatus != LaundryStatus.clean) {
        return false;
      }

      return true;
    }).toList();

    candidates.sort((Garment a, Garment b) {
      final OutfitScore scoreA = scorer.scoreGarment(
        candidate: a,
        context: context,
      );

      final OutfitScore scoreB = scorer.scoreGarment(
        candidate: b,
        context: context,
      );

      return scoreB.total.compareTo(scoreA.total);
    });

    return candidates.take(limit).toList();
  }
}

class _ScoredGarment {
  const _ScoredGarment({
    required this.garment,
    required this.score,
  });

  final Garment garment;
  final OutfitScore score;

}