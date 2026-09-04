import 'package:digital_wardrobe_app/features/ootd/models/outfit_candidate.dart';

class OotdScoringWeights {
  const OotdScoringWeights({
    this.weather = 0.25,
    this.occasion = 0.25,
    this.color = 0.15,
    this.style = 0.12,
    this.preference = 0.10,
    this.wearDiversity = 0.13,
  });

  final double weather;
  final double occasion;
  final double color;
  final double style;
  final double preference;
  final double wearDiversity;

  double get total =>
      weather + occasion + color + style + preference + wearDiversity;
}

class OotdScoringConfig {
  const OotdScoringConfig({
    this.weights = const OotdScoringWeights(),
    this.minimumWeatherScore = 45,
    this.minimumOccasionScore = 45,
    this.minimumQualityForRotationBonus = 68,
  });

  final OotdScoringWeights weights;
  final double minimumWeatherScore;
  final double minimumOccasionScore;
  final double minimumQualityForRotationBonus;
}

class OotdComponentScore {
  const OotdComponentScore({
    required this.score,
    this.reasons = const <String>[],
  });

  final double score;
  final List<String> reasons;
}

class OotdScore {
  const OotdScore({
    required this.candidate,
    required this.total,
    required this.weather,
    required this.occasion,
    required this.color,
    required this.style,
    required this.preference,
    required this.rotation,
    required this.season,
    required this.novelty,
    required this.reasons,
  });

  final OutfitCandidate candidate;
  final double total;
  final double weather;
  final double occasion;
  final double color;
  final double style;
  final double preference;
  final double rotation;
  final double season;
  final double novelty;
  final List<String> reasons;
}
