import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/wear_log.dart';
import 'package:digital_wardrobe_app/features/ootd/models/daily_context.dart';
import 'package:digital_wardrobe_app/features/ootd/models/ootd_score.dart';
import 'package:digital_wardrobe_app/features/ootd/models/outfit_candidate.dart';
import 'package:digital_wardrobe_app/features/ootd/rules/hard_rule_engine.dart';
import 'package:digital_wardrobe_app/features/ootd/scoring/color_harmony_scorer.dart';
import 'package:digital_wardrobe_app/features/ootd/scoring/novelty_scorer.dart';
import 'package:digital_wardrobe_app/features/ootd/scoring/occasion_scorer.dart';
import 'package:digital_wardrobe_app/features/ootd/scoring/preference_scorer.dart';
import 'package:digital_wardrobe_app/features/ootd/scoring/rotation_scorer.dart';
import 'package:digital_wardrobe_app/features/ootd/scoring/season_scorer.dart';
import 'package:digital_wardrobe_app/features/ootd/scoring/style_compatibility_scorer.dart';
import 'package:digital_wardrobe_app/features/ootd/scoring/weather_scorer.dart';
import 'package:digital_wardrobe_app/features/ootd/services/candidate_generator.dart';
import 'package:digital_wardrobe_app/features/ootd/services/daily_context_interpreter.dart';
import 'package:digital_wardrobe_app/features/ootd/services/ootd_ranker.dart';

class OotdEngine {
  const OotdEngine({
    this.contextInterpreter = const DailyContextInterpreter(),
    this.candidateGenerator = const CandidateGenerator(),
    this.hardRules = const HardRuleEngine(),
    this.weatherScorer = const WeatherScorer(),
    this.occasionScorer = const OccasionScorer(),
    this.colorScorer = const ColorHarmonyScorer(),
    this.styleScorer = const StyleCompatibilityScorer(),
    this.rotationScorer = const RotationScorer(),
    this.preferenceScorer = const PreferenceScorer(),
    this.seasonScorer = const SeasonScorer(),
    this.noveltyScorer = const NoveltyScorer(),
    this.ranker = const OotdRanker(),
  });

  final DailyContextInterpreter contextInterpreter;
  final CandidateGenerator candidateGenerator;
  final HardRuleEngine hardRules;
  final WeatherScorer weatherScorer;
  final OccasionScorer occasionScorer;
  final ColorHarmonyScorer colorScorer;
  final StyleCompatibilityScorer styleScorer;
  final RotationScorer rotationScorer;
  final PreferenceScorer preferenceScorer;
  final SeasonScorer seasonScorer;
  final NoveltyScorer noveltyScorer;
  final OotdRanker ranker;

  List<OotdScore> recommend({
    required List<Garment> garments,
    required List<WearLog> wearLogs,
    required DailyContext context,
    String? memberId,
    DateTime? now,
    int limit = 3,
  }) {
    final DateTime resolvedNow = now ?? DateTime.now();
    final requirements = contextInterpreter.interpret(context);
    final List<Garment> available = garments
        .where(
          (Garment garment) =>
              !garment.isArchived &&
              garment.laundryStatus == LaundryStatus.clean &&
              garment.availabilityStatus.isPhysicallyAvailable &&
              garment.ironingStatus != IroningStatus.needsIroning &&
              (memberId == null || garment.memberId == memberId),
        )
        .toList();

    final List<OutfitCandidate> candidates = candidateGenerator.generate(
      available,
    );
    final List<OotdScore> scored = <OotdScore>[];

    for (final OutfitCandidate candidate in candidates) {
      final HardRuleResult hardRuleResult = hardRules.evaluate(
        candidate: candidate,
        requirements: requirements,
        memberId: memberId,
      );
      if (!hardRuleResult.accepted) {
        continue;
      }

      final OotdComponentScore weather = weatherScorer.score(
        candidate: candidate,
        context: context,
        requirements: requirements,
      );
      final OotdComponentScore occasion = occasionScorer.score(
        candidate: candidate,
        context: context,
        requirements: requirements,
      );
      final OotdComponentScore color = colorScorer.score(candidate);
      final OotdComponentScore style = styleScorer.score(candidate);
      final OotdComponentScore preference = preferenceScorer.score(
        candidate: candidate,
        wearLogs: wearLogs,
      );
      final OotdComponentScore season = seasonScorer.score(
        candidate: candidate,
        context: context,
      );
      final OotdComponentScore novelty = noveltyScorer.score(
        candidate: candidate,
        wearLogs: wearLogs,
        now: resolvedNow,
      );

      final double baseQuality =
          weather.score * 0.35 +
          occasion.score * 0.30 +
          color.score * 0.18 +
          style.score * 0.17;
      final OotdComponentScore rotation = rotationScorer.score(
        candidate: candidate,
        wearLogs: wearLogs,
        now: resolvedNow,
        baseQuality: baseQuality,
        minimumQualityForBonus: ranker.config.minimumQualityForRotationBonus,
      );

      final List<String> reasons = <String>[
        ...weather.reasons,
        ...occasion.reasons,
        ...color.reasons,
        ...style.reasons,
        ...rotation.reasons,
        ...preference.reasons,
        ...season.reasons,
        ...novelty.reasons,
      ];

      final OotdScore raw = OotdScore(
        candidate: candidate,
        total: 0,
        weather: weather.score,
        occasion: occasion.score,
        color: color.score,
        style: style.score,
        preference: preference.score,
        rotation: rotation.score,
        season: season.score,
        novelty: novelty.score,
        reasons: reasons,
      );

      scored.add(ranker.combine(raw: raw, reasons: reasons));
    }

    return ranker.diverseTop(scored, limit: limit);
  }
}
