import 'dart:math';

import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/wear_log.dart';
import 'package:digital_wardrobe_app/features/ootd/models/ootd_score.dart';
import 'package:digital_wardrobe_app/features/ootd/models/outfit_candidate.dart';

class RotationScorer {
  const RotationScorer();

  OotdComponentScore score({
    required OutfitCandidate candidate,
    required List<WearLog> wearLogs,
    required DateTime now,
    required double baseQuality,
    required double minimumQualityForBonus,
  }) {
    double score = 78;
    final Map<String, DateTime> lastWornByGarment = <String, DateTime>{};

    for (final WearLog log in wearLogs) {
      final DateTime? existing = lastWornByGarment[log.garmentId];
      if (existing == null || log.wornDate.isAfter(existing)) {
        lastWornByGarment[log.garmentId] = log.wornDate;
      }
    }

    for (final Garment garment in candidate.garments) {
      final DateTime? lastWorn =
          lastWornByGarment[garment.id] ?? garment.lastWornDate;
      if (lastWorn == null) {
        if (baseQuality >= minimumQualityForBonus) {
          score += 2;
        }
        continue;
      }

      final int days = now.difference(lastWorn).inDays;
      final double weight = _categoryPenaltyWeight(garment.category);
      if (days <= 1) {
        score -= 22 * weight;
      } else if (days <= 3) {
        score -= 14 * weight;
      } else if (days <= 7) {
        score -= 8 * weight;
      } else if (days >= 45 && baseQuality >= minimumQualityForBonus) {
        score += 4 * weight;
      }
    }

    final double repetitionPenalty = _recentCombinationPenalty(
      candidate,
      wearLogs,
      now,
    );
    score -= repetitionPenalty;

    final List<String> reasons = <String>[];
    if (score >= 78) {
      reasons.add('These pieces have not been worn together recently.');
    }
    if (repetitionPenalty >= 12) {
      reasons.add('A recently repeated combination was de-prioritized.');
    }

    return OotdComponentScore(
      score: score.clamp(0, 100).toDouble(),
      reasons: reasons,
    );
  }

  double _categoryPenaltyWeight(GarmentCategory category) {
    return switch (category) {
      GarmentCategory.top || GarmentCategory.dress => 1.0,
      GarmentCategory.bottom => 0.7,
      GarmentCategory.shoe => 0.35,
      GarmentCategory.outerwear => 0.2,
      _ => 0.15,
    };
  }

  double _recentCombinationPenalty(
    OutfitCandidate candidate,
    List<WearLog> logs,
    DateTime now,
  ) {
    final Set<String> majorIds = candidate.garments
        .where((Garment garment) => _majorCategory(garment.category))
        .map((Garment garment) => garment.id)
        .toSet();
    if (majorIds.isEmpty) {
      return 0;
    }

    final Map<String, Set<String>> idsBySavedOutfit = <String, Set<String>>{};
    for (final WearLog log in logs) {
      if (now.difference(log.wornDate).inDays > 21) {
        continue;
      }

      final String? outfitId = log.outfitId;
      if (outfitId == null) {
        continue;
      }

      idsBySavedOutfit
          .putIfAbsent(outfitId, () => <String>{})
          .add(log.garmentId);
    }

    double worstPenalty = 0;
    for (final Set<String> wornIds in idsBySavedOutfit.values) {
      final int overlap = majorIds.intersection(wornIds).length;
      final double similarity = overlap / majorIds.length;
      if (similarity >= 1) {
        worstPenalty = max(worstPenalty, 28);
      } else if (similarity >= 0.75) {
        worstPenalty = max(worstPenalty, 18);
      } else if (similarity >= 0.5) {
        worstPenalty = max(worstPenalty, 8);
      }
    }

    return worstPenalty;
  }

  bool _majorCategory(GarmentCategory category) {
    return category == GarmentCategory.top ||
        category == GarmentCategory.bottom ||
        category == GarmentCategory.dress ||
        category == GarmentCategory.shoe ||
        category == GarmentCategory.outerwear;
  }
}
