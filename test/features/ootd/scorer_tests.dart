import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/wear_log.dart';
import 'package:digital_wardrobe_app/features/ootd/models/daily_context.dart';
import 'package:digital_wardrobe_app/features/ootd/models/daily_requirements.dart';
import 'package:digital_wardrobe_app/features/ootd/models/outfit_candidate.dart';
import 'package:digital_wardrobe_app/features/ootd/scoring/color_harmony_scorer.dart';
import 'package:digital_wardrobe_app/features/ootd/scoring/novelty_scorer.dart';
import 'package:digital_wardrobe_app/features/ootd/scoring/occasion_scorer.dart';
import 'package:digital_wardrobe_app/features/ootd/scoring/preference_scorer.dart';
import 'package:digital_wardrobe_app/features/ootd/scoring/rotation_scorer.dart';
import 'package:digital_wardrobe_app/features/ootd/scoring/season_scorer.dart';
import 'package:digital_wardrobe_app/features/ootd/scoring/style_compatibility_scorer.dart';
import 'package:digital_wardrobe_app/features/ootd/scoring/weather_scorer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Garment makeGarment({
    required String id,
    required GarmentCategory category,
    String? fabric,
    String? fabricWeight,
    String? sleeveLength,
    String? fit,
    String? pattern,
    String? colorHex,
    String? secondaryColorHex,
    List<String> occasions = const <String>[],
    List<String> seasons = const <String>[],
    List<String> moods = const <String>[],
    int wearCount = 0,
    DateTime? lastWornDate,
    String? name,
  }) {
    return Garment(
      id: id,
      name: name ?? 'Garment $id',
      memberId: 'member-1',
      category: category,
      photoPaths: const <String>[],
      photoUrls: const <String>[],
      fabric: fabric,
      fabricWeight: fabricWeight,
      sleeveLength: sleeveLength,
      fit: fit,
      pattern: pattern,
      colorHex: colorHex,
      secondaryColorHex: secondaryColorHex,
      occasions: occasions,
      seasons: seasons,
      moods: moods,
      wearCount: wearCount,
      lastWornDate: lastWornDate,
    );
  }

  OutfitCandidate separatedCandidate({
    String topFabric = 'Cotton',
    String bottomFabric = 'Cotton',
    String shoeFabric = 'Leather',
    String? topColor,
    String? bottomColor,
  }) {
    return OutfitCandidate(
      templateType: OotdTemplateType.separated,
      garments: <Garment>[
        makeGarment(
          id: 'top-1',
          category: GarmentCategory.top,
          fabric: topFabric,
          fabricWeight: 'Medium',
          sleeveLength: 'Short Sleeve',
          fit: 'Regular',
          colorHex: topColor,
        ),
        makeGarment(
          id: 'bottom-1',
          category: GarmentCategory.bottom,
          fabric: bottomFabric,
          fit: 'Straight',
          colorHex: bottomColor,
        ),
        makeGarment(
          id: 'shoe-1',
          category: GarmentCategory.shoe,
          fabric: shoeFabric,
        ),
      ],
    );
  }

  const DailyRequirements defaultRequirements = DailyRequirements(
    targetWarmth: 5,
    targetBreathability: 5,
    rainProtectionNeed: 3,
    windProtectionNeed: 2,
    targetFormality: 5,
    preferLightLayers: false,
    preferRemovableLayer: false,
    avoidSuede: false,
    avoidOpenFootwear: false,
    preferComfortableFootwear: false,
    avoidRestrictiveFits: false,
  );

  final DailyContext defaultContext = DailyContext(
    temperature: 24,
    feelsLike: 24,
    humidity: 50,
    rainProbability: 15,
    windSpeed: 8,
    date: DateTime(2026, 6, 15),
    season: 'summer',
  );

  group('WeatherScorer', () {
    const WeatherScorer scorer = WeatherScorer();
    final candidate = separatedCandidate(topFabric: 'Linen');

    test('returns 72 when weather is unavailable', () {
      final result = scorer.score(
        candidate: candidate,
        context: DailyContext(
          date: DateTime(2026, 6, 15),
          season: 'summer',
        ),
        requirements: defaultRequirements,
      );

      expect(result.score, 72);
      expect(result.reasons, isNotEmpty);
    });

    test('hot weather gives higher score to breathable linen', () {
      final hotRequirements = DailyRequirements(
        targetWarmth: 1.5,
        targetBreathability: 9.5,
        rainProtectionNeed: 2,
        windProtectionNeed: 2,
        targetFormality: 5,
        preferLightLayers: true,
        preferRemovableLayer: false,
        avoidSuede: false,
        avoidOpenFootwear: false,
        preferComfortableFootwear: false,
        avoidRestrictiveFits: false,
      );

      final result = scorer.score(
        candidate: candidate,
        context: DailyContext(
          temperature: 35,
          feelsLike: 38,
          humidity: 80,
          rainProbability: 10,
          date: DateTime(2026, 8, 24),
          season: 'summer',
        ),
        requirements: hotRequirements,
      );

      expect(result.score, greaterThan(50));
    });

    test('cold weather penalizes lightweight fabrics', () {
      final coldRequirements = DailyRequirements(
        targetWarmth: 8.5,
        targetBreathability: 3,
        rainProtectionNeed: 2,
        windProtectionNeed: 2,
        targetFormality: 5,
        preferLightLayers: false,
        preferRemovableLayer: false,
        avoidSuede: false,
        avoidOpenFootwear: false,
        preferComfortableFootwear: false,
        avoidRestrictiveFits: false,
      );

      final result = scorer.score(
        candidate: candidate,
        context: DailyContext(
          temperature: 3,
          feelsLike: -1,
          humidity: 40,
          rainProbability: 10,
          date: DateTime(2026, 1, 15),
          season: 'winter',
        ),
        requirements: coldRequirements,
      );

      expect(result.score, lessThan(60));
    });

    test('outerwear bonus in windy conditions with removable layer', () {
      final windyRequirements = DailyRequirements(
        targetWarmth: 5,
        targetBreathability: 5,
        rainProtectionNeed: 3,
        windProtectionNeed: 6,
        targetFormality: 5,
        preferLightLayers: false,
        preferRemovableLayer: true,
        avoidSuede: false,
        avoidOpenFootwear: false,
        preferComfortableFootwear: false,
        avoidRestrictiveFits: false,
      );

      final withOuterwear = OutfitCandidate(
        templateType: OotdTemplateType.separated,
        garments: <Garment>[
          makeGarment(
            id: 'top-1',
            category: GarmentCategory.top,
            fabric: 'Cotton',
          ),
          makeGarment(
            id: 'bottom-1',
            category: GarmentCategory.bottom,
            fabric: 'Cotton',
          ),
          makeGarment(
            id: 'shoe-1',
            category: GarmentCategory.shoe,
          ),
          makeGarment(
            id: 'jacket-1',
            category: GarmentCategory.outerwear,
            fabric: 'Nylon',
          ),
        ],
      );

      final result = scorer.score(
        candidate: withOuterwear,
        context: defaultContext,
        requirements: windyRequirements,
      );

      expect(result.score, greaterThan(60));
    });

    test('rain protection penalty for suede shoes in rain', () {
      final rainyRequirements = DailyRequirements(
        targetWarmth: 5,
        targetBreathability: 5,
        rainProtectionNeed: 7,
        windProtectionNeed: 2,
        targetFormality: 5,
        preferLightLayers: false,
        preferRemovableLayer: false,
        avoidSuede: true,
        avoidOpenFootwear: false,
        preferComfortableFootwear: false,
        avoidRestrictiveFits: false,
      );

      final suedeShoes = OutfitCandidate(
        templateType: OotdTemplateType.separated,
        garments: <Garment>[
          makeGarment(id: 'top-1', category: GarmentCategory.top),
          makeGarment(id: 'bottom-1', category: GarmentCategory.bottom),
          makeGarment(
            id: 'shoe-1',
            category: GarmentCategory.shoe,
            fabric: 'Suede',
            name: 'Suede Loafers',
          ),
        ],
      );

      final result = scorer.score(
        candidate: suedeShoes,
        context: defaultContext,
        requirements: rainyRequirements,
      );

      expect(result.score, lessThan(75));
    });
  });

  group('OccasionScorer', () {
    const OccasionScorer scorer = OccasionScorer();

    test('formal occasion matches formal garments', () {
      final formalCandidate = OutfitCandidate(
        templateType: OotdTemplateType.separated,
        garments: <Garment>[
          makeGarment(
            id: 'top-1',
            category: GarmentCategory.top,
            fabric: 'Cotton',
            fit: 'Tailored',
            occasions: const <String>['formal'],
          ),
          makeGarment(
            id: 'bottom-1',
            category: GarmentCategory.bottom,
            fabric: 'Wool',
            fit: 'Tailored',
            occasions: const <String>['formal'],
          ),
          makeGarment(
            id: 'shoe-1',
            category: GarmentCategory.shoe,
            fabric: 'Leather',
            occasions: const <String>['formal'],
          ),
        ],
      );

      final requirements = DailyRequirements(
        targetWarmth: 5,
        targetBreathability: 5,
        rainProtectionNeed: 3,
        windProtectionNeed: 2,
        targetFormality: 8,
        preferLightLayers: false,
        preferRemovableLayer: false,
        avoidSuede: false,
        avoidOpenFootwear: false,
        preferComfortableFootwear: false,
        avoidRestrictiveFits: false,
      );

      final result = scorer.score(
        candidate: formalCandidate,
        context: DailyContext(
          temperature: 22,
          occasion: 'formal',
          date: DateTime(2026, 6, 15),
          season: 'summer',
        ),
        requirements: requirements,
      );

      expect(result.score, greaterThan(60));
    });

    test('casual occasion does not penalize casual garments', () {
      final casualCandidate = separatedCandidate(
        topFabric: 'Cotton',
        bottomFabric: 'Denim',
      );

      final requirements = DailyRequirements(
        targetWarmth: 5,
        targetBreathability: 5,
        rainProtectionNeed: 3,
        windProtectionNeed: 2,
        targetFormality: 3,
        preferLightLayers: false,
        preferRemovableLayer: false,
        avoidSuede: false,
        avoidOpenFootwear: false,
        preferComfortableFootwear: false,
        avoidRestrictiveFits: false,
      );

      final result = scorer.score(
        candidate: casualCandidate,
        context: DailyContext(
          temperature: 24,
          occasion: 'casual',
          date: DateTime(2026, 6, 15),
          season: 'summer',
        ),
        requirements: requirements,
      );

      expect(result.score, greaterThan(50));
    });

    test('mood tag matching increases score', () {
      final relaxedCandidate = OutfitCandidate(
        templateType: OotdTemplateType.separated,
        garments: <Garment>[
          makeGarment(
            id: 'top-1',
            category: GarmentCategory.top,
            fabric: 'Cotton',
            moods: const <String>['relaxed'],
          ),
          makeGarment(
            id: 'bottom-1',
            category: GarmentCategory.bottom,
            fabric: 'Denim',
            moods: const <String>['relaxed'],
          ),
          makeGarment(
            id: 'shoe-1',
            category: GarmentCategory.shoe,
            fabric: 'Canvas',
            moods: const <String>['relaxed'],
          ),
        ],
      );

      final result = scorer.score(
        candidate: relaxedCandidate,
        context: DailyContext(
          temperature: 24,
          mood: 'relaxed',
          date: DateTime(2026, 6, 15),
          season: 'summer',
        ),
        requirements: defaultRequirements,
      );

      expect(result.score, greaterThan(60));
    });
  });

  group('ColorHarmonyScorer', () {
    const ColorHarmonyScorer scorer = ColorHarmonyScorer();

    test('all-neutral palette scores well', () {
      final candidate = separatedCandidate(
        topColor: '#FFFFFF',
        bottomColor: '#111111',
      );

      final result = scorer.score(candidate);
      expect(result.score, greaterThan(80));
    });

    test('too many saturated colors reduces score', () {
      final candidate = OutfitCandidate(
        templateType: OotdTemplateType.separated,
        garments: <Garment>[
          makeGarment(
            id: 'top-1',
            category: GarmentCategory.top,
            colorHex: '#FF0000',
            pattern: 'Solid',
          ),
          makeGarment(
            id: 'bottom-1',
            category: GarmentCategory.bottom,
            colorHex: '#00FF00',
            pattern: 'Solid',
          ),
          makeGarment(
            id: 'shoe-1',
            category: GarmentCategory.shoe,
            colorHex: '#0000FF',
            pattern: 'Solid',
          ),
        ],
      );

      final result = scorer.score(candidate);
      expect(result.score, lessThan(80));
    });

    test('single garment with one color returns baseline', () {
      final candidate = OutfitCandidate(
        templateType: OotdTemplateType.dress,
        garments: <Garment>[
          makeGarment(
            id: 'dress-1',
            category: GarmentCategory.dress,
            colorHex: '#333333',
          ),
        ],
      );

      final result = scorer.score(candidate);
      expect(result.score, 72);
    });
  });

  group('StyleCompatibilityScorer', () {
    const StyleCompatibilityScorer scorer = StyleCompatibilityScorer();

    test('balanced outfit scores well', () {
      final candidate = OutfitCandidate(
        templateType: OotdTemplateType.separated,
        garments: <Garment>[
          makeGarment(
            id: 'top-1',
            category: GarmentCategory.top,
            fabric: 'Cotton',
            fit: 'Slim',
            pattern: 'Solid',
          ),
          makeGarment(
            id: 'bottom-1',
            category: GarmentCategory.bottom,
            fabric: 'Denim',
            fit: 'Straight',
            pattern: 'Solid',
          ),
          makeGarment(
            id: 'shoe-1',
            category: GarmentCategory.shoe,
            fabric: 'Leather',
          ),
        ],
      );

      final result = scorer.score(candidate);
      expect(result.score, greaterThan(70));
    });

    test('oversized top + wide leg + oversized outerwear penalizes', () {
      final candidate = OutfitCandidate(
        templateType: OotdTemplateType.separated,
        garments: <Garment>[
          makeGarment(
            id: 'top-1',
            category: GarmentCategory.top,
            fit: 'Oversized',
            pattern: 'Solid',
          ),
          makeGarment(
            id: 'bottom-1',
            category: GarmentCategory.bottom,
            fit: 'Wide-leg',
            pattern: 'Solid',
          ),
          makeGarment(
            id: 'shoe-1',
            category: GarmentCategory.shoe,
          ),
          makeGarment(
            id: 'jacket-1',
            category: GarmentCategory.outerwear,
            fit: 'Oversized',
          ),
        ],
      );

      final result = scorer.score(candidate);
      expect(result.score, lessThan(78));
    });

    test('cotton + denim fabric compatibility bonus', () {
      final candidate = OutfitCandidate(
        templateType: OotdTemplateType.separated,
        garments: <Garment>[
          makeGarment(
            id: 'top-1',
            category: GarmentCategory.top,
            fabric: 'Cotton',
            pattern: 'Solid',
          ),
          makeGarment(
            id: 'bottom-1',
            category: GarmentCategory.bottom,
            fabric: 'Denim',
            pattern: 'Solid',
          ),
          makeGarment(
            id: 'shoe-1',
            category: GarmentCategory.shoe,
            fabric: 'Leather',
          ),
        ],
      );

      final result = scorer.score(candidate);
      expect(result.score, greaterThanOrEqualTo(78));
    });
  });

  group('PreferenceScorer', () {
    const PreferenceScorer scorer = PreferenceScorer();

    test('returns 72 for new wardrobe with no wear history', () {
      final candidate = separatedCandidate();
      final result = scorer.score(
        candidate: candidate,
        wearLogs: const <WearLog>[],
      );

      expect(result.score, 72);
    });

    test('frequently worn items boost preference score', () {
      final candidate = separatedCandidate();
      final wearLogs = <WearLog>[
        WearLog(
          id: 'log-1',
          memberId: 'member-1',
          garmentId: 'top-1',
          wornDate: DateTime(2026, 6, 1),
        ),
        WearLog(
          id: 'log-2',
          memberId: 'member-1',
          garmentId: 'top-1',
          wornDate: DateTime(2026, 5, 15),
        ),
        WearLog(
          id: 'log-3',
          memberId: 'member-1',
          garmentId: 'bottom-1',
          wornDate: DateTime(2026, 5, 20),
        ),
      ];

      final result = scorer.score(
        candidate: candidate,
        wearLogs: wearLogs,
      );

      expect(result.score, greaterThan(75));
    });
  });

  group('RotationScorer', () {
    const RotationScorer scorer = RotationScorer();

    test('never-worn garment gets bonus if quality is high enough', () {
      final candidate = separatedCandidate();
      final result = scorer.score(
        candidate: candidate,
        wearLogs: const <WearLog>[],
        now: DateTime(2026, 6, 15),
        baseQuality: 75,
        minimumQualityForBonus: 68,
      );

      expect(result.score, greaterThan(78));
    });

    test('recently worn garment gets penalty', () {
      final candidate = separatedCandidate();
      final wearLogs = <WearLog>[
        WearLog(
          id: 'log-1',
          memberId: 'member-1',
          garmentId: 'top-1',
          wornDate: DateTime(2026, 6, 14),
        ),
      ];

      final result = scorer.score(
        candidate: candidate,
        wearLogs: wearLogs,
        now: DateTime(2026, 6, 15),
        baseQuality: 75,
        minimumQualityForBonus: 68,
      );

      expect(result.score, lessThan(78));
    });

    test('recently worn shoes get smaller penalty than tops', () {
      final topCandidate = OutfitCandidate(
        templateType: OotdTemplateType.separated,
        garments: <Garment>[
          makeGarment(
            id: 'top-1',
            category: GarmentCategory.top,
            fabric: 'Cotton',
          ),
          makeGarment(id: 'bottom-1', category: GarmentCategory.bottom),
          makeGarment(id: 'shoe-1', category: GarmentCategory.shoe),
        ],
      );

      final shoeCandidate = OutfitCandidate(
        templateType: OotdTemplateType.separated,
        garments: <Garment>[
          makeGarment(id: 'top-1', category: GarmentCategory.top),
          makeGarment(id: 'bottom-1', category: GarmentCategory.bottom),
          makeGarment(
            id: 'shoe-1',
            category: GarmentCategory.shoe,
            fabric: 'Leather',
          ),
        ],
      );

      final wearLogs = <WearLog>[
        WearLog(
          id: 'log-top',
          memberId: 'member-1',
          garmentId: 'top-1',
          wornDate: DateTime(2026, 6, 14),
        ),
        WearLog(
          id: 'log-shoe',
          memberId: 'member-1',
          garmentId: 'shoe-1',
          wornDate: DateTime(2026, 6, 14),
        ),
      ];

      final topResult = scorer.score(
        candidate: topCandidate,
        wearLogs: wearLogs,
        now: DateTime(2026, 6, 15),
        baseQuality: 75,
        minimumQualityForBonus: 68,
      );

      final shoeResult = scorer.score(
        candidate: shoeCandidate,
        wearLogs: wearLogs,
        now: DateTime(2026, 6, 15),
        baseQuality: 75,
        minimumQualityForBonus: 68,
      );

      expect(topResult.score, lessThanOrEqualTo(shoeResult.score));
    });
  });

  group('SeasonScorer', () {
    const SeasonScorer scorer = SeasonScorer();

    test('garments tagged with current season score higher', () {
      final summerCandidate = OutfitCandidate(
        templateType: OotdTemplateType.separated,
        garments: <Garment>[
          makeGarment(
            id: 'top-1',
            category: GarmentCategory.top,
            seasons: const <String>['summer'],
          ),
          makeGarment(
            id: 'bottom-1',
            category: GarmentCategory.bottom,
            seasons: const <String>['summer'],
          ),
          makeGarment(
            id: 'shoe-1',
            category: GarmentCategory.shoe,
            seasons: const <String>['summer'],
          ),
        ],
      );

      final winterCandidate = OutfitCandidate(
        templateType: OotdTemplateType.separated,
        garments: <Garment>[
          makeGarment(
            id: 'top-1',
            category: GarmentCategory.top,
            seasons: const <String>['winter'],
          ),
          makeGarment(
            id: 'bottom-1',
            category: GarmentCategory.bottom,
            seasons: const <String>['winter'],
          ),
          makeGarment(
            id: 'shoe-1',
            category: GarmentCategory.shoe,
            seasons: const <String>['winter'],
          ),
        ],
      );

      final context = DailyContext(
        temperature: 28,
        date: DateTime(2026, 8, 24),
        season: 'summer',
      );

      final summerResult = scorer.score(
        candidate: summerCandidate,
        context: context,
      );

      final winterResult = scorer.score(
        candidate: winterCandidate,
        context: context,
      );

      expect(summerResult.score, greaterThan(winterResult.score));
    });

    test('all-season garments are neutral', () {
      final candidate = OutfitCandidate(
        templateType: OotdTemplateType.separated,
        garments: <Garment>[
          makeGarment(
            id: 'top-1',
            category: GarmentCategory.top,
            seasons: const <String>['all'],
          ),
          makeGarment(
            id: 'bottom-1',
            category: GarmentCategory.bottom,
            seasons: const <String>['all'],
          ),
          makeGarment(
            id: 'shoe-1',
            category: GarmentCategory.shoe,
            seasons: const <String>['all'],
          ),
        ],
      );

      final result = scorer.score(
        candidate: candidate,
        context: DailyContext(
          temperature: 24,
          date: DateTime(2026, 6, 15),
          season: 'summer',
        ),
      );

      expect(result.score, inInclusiveRange(70, 100));
    });
  });

  group('NoveltyScorer', () {
    const NoveltyScorer scorer = NoveltyScorer();

    test('all fresh pieces score higher than all recently worn', () {
      final candidate = separatedCandidate();

      final freshResult = scorer.score(
        candidate: candidate,
        wearLogs: const <WearLog>[],
        now: DateTime(2026, 6, 15),
      );

      final staleLogs = <WearLog>[
        WearLog(
          id: 'log-1',
          memberId: 'member-1',
          garmentId: 'top-1',
          wornDate: DateTime(2026, 6, 10),
        ),
        WearLog(
          id: 'log-2',
          memberId: 'member-1',
          garmentId: 'bottom-1',
          wornDate: DateTime(2026, 6, 8),
        ),
        WearLog(
          id: 'log-3',
          memberId: 'member-1',
          garmentId: 'shoe-1',
          wornDate: DateTime(2026, 6, 5),
        ),
      ];

      final staleResult = scorer.score(
        candidate: candidate,
        wearLogs: staleLogs,
        now: DateTime(2026, 6, 15),
      );

      expect(freshResult.score, greaterThan(staleResult.score));
    });
  });
}
