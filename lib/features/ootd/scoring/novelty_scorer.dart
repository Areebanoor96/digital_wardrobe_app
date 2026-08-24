import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/wear_log.dart';
import 'package:digital_wardrobe_app/features/ootd/models/ootd_score.dart';
import 'package:digital_wardrobe_app/features/ootd/models/outfit_candidate.dart';

class NoveltyScorer {
  const NoveltyScorer();

  OotdComponentScore score({
    required OutfitCandidate candidate,
    required List<WearLog> wearLogs,
    required DateTime now,
  }) {
    final Set<String> recentIds = wearLogs
        .where((WearLog log) => now.difference(log.wornDate).inDays <= 30)
        .map((WearLog log) => log.garmentId)
        .toSet();

    final int freshPieces = candidate.garments
        .where((Garment garment) => !recentIds.contains(garment.id))
        .length;

    final double score = (68 + (freshPieces / candidate.garments.length) * 24)
        .clamp(0, 100)
        .toDouble();

    return OotdComponentScore(
      score: score,
      reasons: score >= 84
          ? const <String>['Adds some variety without overpowering the outfit.']
          : const <String>[],
    );
  }
}
