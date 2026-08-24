import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/ootd/models/daily_context.dart';
import 'package:digital_wardrobe_app/features/ootd/models/ootd_score.dart';
import 'package:digital_wardrobe_app/features/ootd/models/outfit_candidate.dart';

class SeasonScorer {
  const SeasonScorer();

  OotdComponentScore score({
    required OutfitCandidate candidate,
    required DailyContext context,
  }) {
    int explicitMatches = 0;
    int explicitConflicts = 0;

    for (final Garment garment in candidate.garments) {
      final List<String> seasons = garment.seasons
          .map((String season) => season.toLowerCase())
          .toList();
      if (seasons.isEmpty || seasons.contains('all')) {
        continue;
      }
      if (seasons.contains(context.season.toLowerCase())) {
        explicitMatches++;
      } else {
        explicitConflicts++;
      }
    }

    final double score = (76 + explicitMatches * 8 - explicitConflicts * 10)
        .clamp(0, 100)
        .toDouble();

    return OotdComponentScore(
      score: score,
      reasons: explicitMatches > 0
          ? <String>['These pieces fit the automatic ${context.season} season.']
          : const <String>[],
    );
  }
}
