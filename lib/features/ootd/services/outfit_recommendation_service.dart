import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/wear_log.dart';
import 'package:digital_wardrobe_app/features/ootd/models/daily_context.dart';
import 'package:digital_wardrobe_app/features/ootd/models/ootd_score.dart';
import 'package:digital_wardrobe_app/features/ootd/models/weather_data.dart';
import 'package:digital_wardrobe_app/features/ootd/services/ootd_engine.dart';
import 'package:digital_wardrobe_app/features/outfits/models/outfit_context.dart';

class OutfitRecommendation {
  const OutfitRecommendation({
    required this.garments,
    required this.reason,
    this.score = 0,
    this.heroGarment,
    this.reasons = const <String>[],
    this.weatherScore = 0,
    this.occasionScore = 0,
    this.colorScore = 0,
    this.styleScore = 0,
    this.rotationScore = 0,
    this.preferenceScore = 0,
    this.noveltyScore = 0,
    this.seasonScore = 0,
    this.label = 'Best Match',
    this.alternatives = const <OutfitRecommendation>[],
  });

  final List<Garment> garments;
  final String reason;
  final int score;
  final Garment? heroGarment;
  final List<String> reasons;
  final int weatherScore;
  final int occasionScore;
  final int colorScore;
  final int styleScore;
  final int rotationScore;
  final int preferenceScore;
  final int noveltyScore;
  final int seasonScore;
  final String label;
  final List<OutfitRecommendation> alternatives;
}

class OutfitRecommendationService {
  const OutfitRecommendationService({this.engine = const OotdEngine()});

  final OotdEngine engine;

  bool isEligibleForRecommendation(List<Garment> garments, {String? memberId}) {
    final List<Garment> active = garments
        .where(
          (Garment garment) =>
              !garment.isArchived &&
              garment.laundryStatus == LaundryStatus.clean &&
              garment.availabilityStatus.isPhysicallyAvailable &&
              garment.ironingStatus != IroningStatus.needsIroning &&
              (memberId == null || garment.memberId == memberId),
        )
        .toList();

    if (active.length < 2) {
      return false;
    }

    bool hasCategory(GarmentCategory category) =>
        active.any((Garment garment) => garment.category == category);

    final bool separated =
        hasCategory(GarmentCategory.top) &&
        hasCategory(GarmentCategory.bottom) &&
        hasCategory(GarmentCategory.shoe);
    final bool dress =
        hasCategory(GarmentCategory.dress) && hasCategory(GarmentCategory.shoe);

    return separated || dress;
  }

  OutfitRecommendation recommend({
    required List<Garment> allGarments,
    Set<String> recentlyWornGarmentIds = const <String>{},
    List<WearLog> wearLogs = const <WearLog>[],
    OutfitContext context = const OutfitContext(),
    WeatherData? weather,
    String? memberId,
    DateTime? now,
  }) {
    final List<OutfitRecommendation> recommendations = recommendMany(
      allGarments: allGarments,
      recentlyWornGarmentIds: recentlyWornGarmentIds,
      wearLogs: wearLogs,
      context: context,
      weather: weather,
      memberId: memberId,
      now: now,
    );

    if (recommendations.isEmpty) {
      return const OutfitRecommendation(
        garments: <Garment>[],
        reason:
            'Add clean, available, ready-to-wear garments that can form a top-bottom-shoes or dress-shoes outfit.',
      );
    }

    return recommendations.first;
  }

  List<OutfitRecommendation> recommendMany({
    required List<Garment> allGarments,
    Set<String> recentlyWornGarmentIds = const <String>{},
    List<WearLog> wearLogs = const <WearLog>[],
    OutfitContext context = const OutfitContext(),
    WeatherData? weather,
    String? memberId,
    DateTime? now,
  }) {
    final DateTime resolvedNow = now ?? DateTime.now();
    final List<WearLog> resolvedLogs = wearLogs.isNotEmpty
        ? wearLogs
        : _logsFromRecentIds(recentlyWornGarmentIds, resolvedNow);
    final DailyContext dailyContext = DailyContext.from(
      weather: weather,
      outfitContext: context,
      date: resolvedNow,
      dressCode: context.dressCode,
      expectedActivityLevel: context.expectedActivityLevel,
      indoor: context.indoor,
      outdoor: context.outdoor,
    );

    final List<OotdScore> scores = engine.recommend(
      garments: allGarments,
      wearLogs: resolvedLogs,
      context: dailyContext,
      memberId: memberId,
      now: resolvedNow,
    );

    final List<String> labels = <String>[
      'Best Match',
      'Stylish Alternative',
      'Something Different',
    ];

    final List<OutfitRecommendation> mapped = <OutfitRecommendation>[
      for (int index = 0; index < scores.length; index++)
        _fromScore(
          scores[index],
          label: labels[index.clamp(0, labels.length - 1).toInt()],
        ),
    ];

    if (mapped.isEmpty) {
      return const <OutfitRecommendation>[];
    }

    return <OutfitRecommendation>[
      mapped.first.copyWithAlternatives(mapped.skip(1).toList()),
      ...mapped.skip(1),
    ];
  }

  List<WearLog> _logsFromRecentIds(Set<String> ids, DateTime now) {
    return ids
        .map(
          (String id) => WearLog(
            id: 'synthetic-$id',
            memberId: '',
            garmentId: id,
            wornDate: now.subtract(const Duration(days: 1)),
          ),
        )
        .toList();
  }

  OutfitRecommendation _fromScore(OotdScore score, {required String label}) {
    return OutfitRecommendation(
      garments: score.candidate.garments,
      reason: _buildReason(score, label),
      score: score.total.round().clamp(0, 100).toInt(),
      heroGarment: score.candidate.garments.firstOrNull,
      reasons: score.reasons,
      weatherScore: score.weather.round().clamp(0, 100).toInt(),
      occasionScore: score.occasion.round().clamp(0, 100).toInt(),
      colorScore: score.color.round().clamp(0, 100).toInt(),
      styleScore: score.style.round().clamp(0, 100).toInt(),
      rotationScore: score.rotation.round().clamp(0, 100).toInt(),
      preferenceScore: score.preference.round().clamp(0, 100).toInt(),
      noveltyScore: score.novelty.round().clamp(0, 100).toInt(),
      seasonScore: score.season.round().clamp(0, 100).toInt(),
      label: label,
    );
  }

  String _buildReason(OotdScore score, String label) {
    final String firstReason =
        score.reasons.firstOrNull ??
        'Balanced across weather, occasion, color, style and rotation.';

    return '$label: ${score.total.round().clamp(0, 100).toInt()}% match. $firstReason';
  }
}

extension on OutfitRecommendation {
  OutfitRecommendation copyWithAlternatives(
    List<OutfitRecommendation> alternatives,
  ) {
    return OutfitRecommendation(
      garments: garments,
      reason: reason,
      score: score,
      heroGarment: heroGarment,
      reasons: reasons,
      weatherScore: weatherScore,
      occasionScore: occasionScore,
      colorScore: colorScore,
      styleScore: styleScore,
      rotationScore: rotationScore,
      preferenceScore: preferenceScore,
      noveltyScore: noveltyScore,
      seasonScore: seasonScore,
      label: label,
      alternatives: alternatives,
    );
  }
}
