import 'dart:math';

import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/ootd/models/daily_context.dart';
import 'package:digital_wardrobe_app/features/ootd/models/daily_requirements.dart';
import 'package:digital_wardrobe_app/features/ootd/models/ootd_score.dart';
import 'package:digital_wardrobe_app/features/ootd/models/outfit_candidate.dart';
import 'package:digital_wardrobe_app/features/ootd/services/garment_metadata_interpreter.dart';

class OccasionScorer {
  const OccasionScorer({
    this.metadataInterpreter = const GarmentMetadataInterpreter(),
  });

  final GarmentMetadataInterpreter metadataInterpreter;

  OotdComponentScore score({
    required OutfitCandidate candidate,
    required DailyContext context,
    required DailyRequirements requirements,
  }) {
    final double formality = _weightedFormality(candidate);
    final double formalityScore = max(
      0,
      100 - ((formality - requirements.targetFormality).abs() * 16),
    );
    final double tagScore = _tagScore(candidate, context.occasion);
    final double moodScore = _tagScore(candidate, context.mood);
    final double total =
        formalityScore * 0.68 + tagScore * 0.22 + moodScore * 0.10;

    final List<String> reasons = <String>[];
    if ((context.occasion ?? '').isNotEmpty && total >= 76) {
      reasons.add('Appropriate for your ${context.occasion} context.');
    }
    if ((context.mood ?? '').isNotEmpty && moodScore >= 72) {
      reasons.add('The outfit supports a ${context.mood} mood.');
    }

    return OotdComponentScore(
      score: total.clamp(0, 100).toDouble(),
      reasons: reasons,
    );
  }

  double _weightedFormality(OutfitCandidate candidate) {
    double total = 0;
    double weightTotal = 0;

    for (final Garment garment in candidate.garments) {
      final double weight = switch (garment.category) {
        GarmentCategory.top ||
        GarmentCategory.bottom ||
        GarmentCategory.dress ||
        GarmentCategory.outerwear => 1.0,
        GarmentCategory.shoe => 0.7,
        _ => 0.25,
      };

      total += metadataInterpreter.interpret(garment).formality * weight;
      weightTotal += weight;
    }

    return weightTotal == 0 ? 4 : total / weightTotal;
  }

  double _tagScore(OutfitCandidate candidate, String? target) {
    if (target == null || target.trim().isEmpty) {
      return 74;
    }

    final String normalized = target.trim().toLowerCase();
    int matches = 0;
    for (final Garment garment in candidate.garments) {
      final List<String> tags = <String>[
        ...garment.occasions,
        ...garment.moods,
      ];
      if (tags.any((String tag) => tag.toLowerCase() == normalized)) {
        matches++;
      }
    }

    return (58 + matches * 12).clamp(0, 100).toDouble();
  }
}
