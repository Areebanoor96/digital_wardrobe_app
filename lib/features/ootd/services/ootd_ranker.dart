import 'package:digital_wardrobe_app/features/ootd/models/ootd_score.dart';

class OotdRanker {
  const OotdRanker({this.config = const OotdScoringConfig()});

  final OotdScoringConfig config;

  OotdScore combine({required OotdScore raw, required List<String> reasons}) {
    final OotdScoringWeights weights = config.weights;

    final double wearDiversity =
        raw.rotation * 0.46 +
        raw.season * 0.31 +
        raw.novelty * 0.23;

    double total =
        raw.weather * weights.weather +
        raw.occasion * weights.occasion +
        raw.color * weights.color +
        raw.style * weights.style +
        raw.preference * weights.preference +
        wearDiversity * weights.wearDiversity;

    final List<String> adjustedReasons = <String>[...reasons];

    if (raw.weather < config.minimumWeatherScore) {
      total *= 0.82;
      adjustedReasons.add('Weather fit is below the recommendation threshold.');
    }

    if (raw.occasion < config.minimumOccasionScore) {
      total *= 0.82;
      adjustedReasons.add(
        'Occasion fit is below the recommendation threshold.',
      );
    }

    return OotdScore(
      candidate: raw.candidate,
      total: total.clamp(0, 100).toDouble(),
      weather: raw.weather,
      occasion: raw.occasion,
      color: raw.color,
      style: raw.style,
      preference: raw.preference,
      rotation: raw.rotation,
      season: raw.season,
      novelty: raw.novelty,
      reasons: _dedupe(adjustedReasons).take(6).toList(),
    );
  }

  List<OotdScore> diverseTop(List<OotdScore> scored, {int limit = 3}) {
    final List<OotdScore> sorted = List<OotdScore>.from(scored)
      ..sort((OotdScore a, OotdScore b) => b.total.compareTo(a.total));
    final List<OotdScore> selected = <OotdScore>[];

    for (final OotdScore score in sorted) {
      if (selected.every(
        (OotdScore existing) => !_tooSimilar(existing, score),
      )) {
        selected.add(score);
      }
      if (selected.length >= limit) {
        break;
      }
    }

    return selected;
  }

  bool _tooSimilar(OotdScore a, OotdScore b) {
    final Set<String> aMajor = a.candidate.garmentIds.take(4).toSet();
    final Set<String> bMajor = b.candidate.garmentIds.take(4).toSet();
    final int overlap = aMajor.intersection(bMajor).length;
    final int denominator = aMajor.length < bMajor.length
        ? aMajor.length
        : bMajor.length;

    if (denominator == 0) {
      return false;
    }

    return overlap / denominator >= 0.75;
  }

  List<String> _dedupe(List<String> reasons) {
    final List<String> result = <String>[];
    for (final String reason in reasons) {
      if (reason.trim().isEmpty || result.contains(reason)) {
        continue;
      }
      result.add(reason);
    }

    return result;
  }
}
