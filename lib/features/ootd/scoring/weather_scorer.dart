import 'dart:math';

import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/ootd/models/daily_context.dart';
import 'package:digital_wardrobe_app/features/ootd/models/daily_requirements.dart';
import 'package:digital_wardrobe_app/features/ootd/models/ootd_score.dart';
import 'package:digital_wardrobe_app/features/ootd/models/outfit_candidate.dart';
import 'package:digital_wardrobe_app/features/ootd/services/garment_metadata_interpreter.dart';

class WeatherScorer {
  const WeatherScorer({
    this.metadataInterpreter = const GarmentMetadataInterpreter(),
  });

  final GarmentMetadataInterpreter metadataInterpreter;

  OotdComponentScore score({
    required OutfitCandidate candidate,
    required DailyContext context,
    required DailyRequirements requirements,
  }) {
    if (context.temperature == null &&
        context.feelsLike == null &&
        context.rainProbability == null) {
      return const OotdComponentScore(
        score: 72,
        reasons: <String>[
          'Weather is unavailable, so the outfit uses non-weather rules.',
        ],
      );
    }

    final double warmth = _weightedMetric(
      candidate,
      (Garment garment) => metadataInterpreter.interpret(garment).warmth,
    );
    final double breathability = _weightedMetric(
      candidate,
      (Garment garment) => metadataInterpreter.interpret(garment).breathability,
    );

    final double thermal = _closeness(warmth, requirements.targetWarmth);
    final double breathable = _closeness(
      breathability,
      requirements.targetBreathability,
    );
    final double rain = _rainScore(candidate, requirements);
    final double wind = requirements.preferRemovableLayer
        ? candidate.containsCategory(GarmentCategory.outerwear)
              ? 92
              : 70
        : 82;
    final double uv = (context.outdoor ?? false) && (context.uvIndex ?? 0) >= 7
        ? breathability >= 6
              ? 86
              : 68
        : 82;

    final double total =
        thermal * 0.36 +
        breathable * 0.28 +
        rain * 0.18 +
        wind * 0.10 +
        uv * 0.08;

    final List<String> reasons = <String>[];
    if (requirements.targetBreathability >= 8 && breathability >= 7) {
      reasons.add('Breathable fabrics suit today\'s warm weather.');
    }
    if (requirements.targetWarmth >= 7 && warmth >= 6.5) {
      reasons.add('The outfit has enough warmth for cooler conditions.');
    }
    if (requirements.rainProtectionNeed >= 7 && rain >= 80) {
      reasons.add('Rain-sensitive fabrics and open footwear are avoided.');
    }
    if (requirements.preferRemovableLayer &&
        candidate.containsCategory(GarmentCategory.outerwear)) {
      reasons.add('A removable layer suits today\'s temperature range.');
    }

    return OotdComponentScore(
      score: total.clamp(0, 100).toDouble(),
      reasons: reasons,
    );
  }

  double _weightedMetric(
    OutfitCandidate candidate,
    double Function(Garment garment) metric,
  ) {
    double total = 0;
    double weightTotal = 0;

    for (final Garment garment in candidate.garments) {
      final double weight = switch (garment.category) {
        GarmentCategory.outerwear => 1.5,
        GarmentCategory.top ||
        GarmentCategory.bottom ||
        GarmentCategory.dress => 1.0,
        GarmentCategory.shoe => 0.35,
        _ => 0.12,
      };
      total += metric(garment) * weight;
      weightTotal += weight;
    }

    return weightTotal == 0 ? 5 : total / weightTotal;
  }

  double _rainScore(OutfitCandidate candidate, DailyRequirements requirements) {
    if (requirements.rainProtectionNeed < 4) {
      return 84;
    }

    double penalty = 0;
    for (final Garment garment in candidate.garments) {
      final String fabric = garment.fabric?.toLowerCase() ?? '';
      final String name = '${garment.name} ${garment.subcategory ?? ''}'
          .toLowerCase();

      if (requirements.avoidSuede && fabric.contains('suede')) {
        penalty += 28;
      }
      if (requirements.avoidOpenFootwear &&
          garment.category == GarmentCategory.shoe &&
          (name.contains('sandal') || name.contains('open'))) {
        penalty += 24;
      }
      if (garment.category == GarmentCategory.outerwear &&
          (fabric.contains('nylon') ||
              fabric.contains('polyester') ||
              name.contains('rain'))) {
        penalty -= 12;
      }
    }

    return (88 - penalty).clamp(0, 100).toDouble();
  }

  double _closeness(double actual, double target) {
    return max(0, 100 - ((actual - target).abs() * 13));
  }
}
