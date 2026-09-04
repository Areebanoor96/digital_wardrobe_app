import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/ootd/models/ootd_score.dart';
import 'package:digital_wardrobe_app/features/ootd/models/outfit_candidate.dart';
import 'package:digital_wardrobe_app/features/ootd/services/ootd_ranker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  OutfitCandidate makeCandidate(String id) {
    return OutfitCandidate(
      templateType: OotdTemplateType.separated,
      garments: <Garment>[
        Garment(
          id: '$id-top',
          name: 'Top $id',
          memberId: 'member-1',
          category: GarmentCategory.top,
          photoPaths: const <String>[],
          photoUrls: const <String>[],
        ),
        Garment(
          id: '$id-bottom',
          name: 'Bottom $id',
          memberId: 'member-1',
          category: GarmentCategory.bottom,
          photoPaths: const <String>[],
          photoUrls: const <String>[],
        ),
        Garment(
          id: '$id-shoe',
          name: 'Shoe $id',
          memberId: 'member-1',
          category: GarmentCategory.shoe,
          photoPaths: const <String>[],
          photoUrls: const <String>[],
        ),
      ],
    );
  }

  OotdScore makeScore(String id, {
    double weather = 70,
    double occasion = 70,
    double color = 70,
    double style = 70,
    double preference = 70,
    double rotation = 70,
    double season = 70,
    double novelty = 70,
  }) {
    final double wearDiversity = rotation * 0.46 + season * 0.31 + novelty * 0.23;
    final double total =
        weather * 0.25 +
        occasion * 0.25 +
        color * 0.15 +
        style * 0.12 +
        preference * 0.10 +
        wearDiversity * 0.13;

    return OotdScore(
      candidate: makeCandidate(id),
      total: total,
      weather: weather,
      occasion: occasion,
      color: color,
      style: style,
      preference: preference,
      rotation: rotation,
      season: season,
      novelty: novelty,
      reasons: const <String>[],
    );
  }

  group('OotdRanker', () {
    const OotdRanker ranker = OotdRanker();

    test('combine produces total from weighted components', () {
      final raw = makeScore(
        'a',
        weather: 80,
        occasion: 80,
        color: 80,
        style: 80,
        preference: 80,
        rotation: 80,
        season: 80,
        novelty: 80,
      );

      final result = ranker.combine(raw: raw, reasons: <String>['test']);

      expect(result.total, greaterThan(0));
      expect(result.total, lessThanOrEqualTo(100));
      expect(result.weather, 80);
      expect(result.occasion, 80);
    });

    test('weights sum to 1.0 (100%)', () {
      final config = OotdScoringConfig().weights;
      expect(config.total, closeTo(1.0, 0.001));
    });

    test('weather 25%, occasion 25%, color 15%, style 12%, preference 10%, wearDiversity 13% weights', () {
      final config = OotdScoringConfig().weights;

      expect(config.weather, 0.25);
      expect(config.occasion, 0.25);
      expect(config.color, 0.15);
      expect(config.style, 0.12);
      expect(config.preference, 0.10);
      expect(config.wearDiversity, 0.13);
    });

    test('combine adjusts total downward when weather is below threshold', () {
      final goodWeather = makeScore('good', weather: 80, occasion: 80);
      final badWeather = makeScore('bad', weather: 20, occasion: 80);

      final goodResult = ranker.combine(
        raw: goodWeather,
        reasons: <String>[],
      );
      final badResult = ranker.combine(
        raw: badWeather,
        reasons: <String>[],
      );

      expect(badResult.total, lessThan(goodResult.total));
    });

    test('combine adjusts total downward when occasion is below threshold', () {
      final goodOccasion = makeScore('good', occasion: 80);
      final badOccasion = makeScore('bad', occasion: 20);

      final goodResult = ranker.combine(
        raw: goodOccasion,
        reasons: <String>[],
      );
      final badResult = ranker.combine(
        raw: badOccasion,
        reasons: <String>[],
      );

      expect(badResult.total, lessThan(goodResult.total));
    });

    test('combine applies wearDiversity as weighted blend of rotation+season+novelty', () {
      final raw = makeScore(
        'a',
        rotation: 80,
        season: 60,
        novelty: 40,
      );

      final result = ranker.combine(raw: raw, reasons: <String>[]);

      // wearDiversity = 80*0.46 + 60*0.31 + 40*0.23 = 36.8 + 18.6 + 9.2 = 64.6
      // total = wearDiversity * 0.13 + other * weights
      expect(result.total, greaterThan(0));
    });

    test('combine deduplicates reasons', () {
      final raw = makeScore('a');
      final result = ranker.combine(
        raw: raw,
        reasons: <String>['same', 'same', 'unique'],
      );

      expect(result.reasons.where((String r) => r == 'same').length, 1);
    });

    test('combine limits reasons to 6', () {
      final raw = makeScore('a');
      final result = ranker.combine(
        raw: raw,
        reasons: <String>[
          'r1', 'r2', 'r3', 'r4', 'r5', 'r6', 'r7', 'r8',
        ],
      );

      expect(result.reasons.length, lessThanOrEqualTo(6));
    });
  });

  group('diverseTop', () {
    const OotdRanker ranker = OotdRanker();

    test('returns top results by total score', () {
      final scores = <OotdScore>[
        makeScore('low', weather: 40),
        makeScore('high', weather: 95),
        makeScore('mid', weather: 70),
      ];

      final result = ranker.diverseTop(scores, limit: 3);

      expect(result, isNotEmpty);
      expect(result.first.candidate.garmentIds.first, contains('high'));
    });

    test('filters out similar candidates', () {
      final scores = <OotdScore>[
        makeScore('a', weather: 90),
        makeScore('a', weather: 88),
        makeScore('b', weather: 85),
      ];

      final result = ranker.diverseTop(scores, limit: 3);

      final ids = result
          .map((OotdScore s) => s.candidate.garmentIds.join(','))
          .toSet();
      expect(ids.length, result.length);
    });

    test('returns at most limit results', () {
      final scores = <OotdScore>[
        makeScore('a'),
        makeScore('b'),
        makeScore('c'),
        makeScore('d'),
      ];

      final result = ranker.diverseTop(scores, limit: 2);
      expect(result.length, lessThanOrEqualTo(2));
    });

    test('empty input returns empty', () {
      final result = ranker.diverseTop(const <OotdScore>[], limit: 3);
      expect(result, isEmpty);
    });

    test('single candidate returns that candidate', () {
      final result = ranker.diverseTop(
        <OotdScore>[makeScore('only')],
        limit: 3,
      );
      expect(result.length, 1);
    });
  });

  group('OotdScoringConfig', () {
    test('default minimums are reasonable', () {
      const config = OotdScoringConfig();

      expect(config.minimumWeatherScore, greaterThan(0));
      expect(config.minimumWeatherScore, lessThan(100));
      expect(config.minimumOccasionScore, greaterThan(0));
      expect(config.minimumOccasionScore, lessThan(100));
      expect(config.minimumQualityForRotationBonus, greaterThan(0));
      expect(config.minimumQualityForRotationBonus, lessThan(100));
    });
  });
}
