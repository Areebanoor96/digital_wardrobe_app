import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/wear_log.dart';
import 'package:digital_wardrobe_app/features/ootd/models/ootd_score.dart';
import 'package:digital_wardrobe_app/features/ootd/models/outfit_candidate.dart';

class PreferenceScorer {
  const PreferenceScorer();

  OotdComponentScore score({
    required OutfitCandidate candidate,
    required List<WearLog> wearLogs,
  }) {
    if (wearLogs.length < 5 &&
        candidate.garments.every((Garment garment) => garment.wearCount == 0)) {
      return const OotdComponentScore(score: 72);
    }

    final Map<String, int> wornCounts = <String, int>{};
    for (final WearLog log in wearLogs) {
      wornCounts.update(
        log.garmentId,
        (int value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    double total = 0;
    for (final Garment garment in candidate.garments) {
      final int count = wornCounts[garment.id] ?? garment.wearCount;
      total += count.clamp(0, 10).toDouble();
    }

    final double average = total / candidate.garments.length;
    final double score = (70 + average * 2.5).clamp(0, 100).toDouble();

    return OotdComponentScore(
      score: score,
      reasons: score >= 80
          ? const <String>['Includes pieces you have reached for before.']
          : const <String>[],
    );
  }
}
