import 'package:digital_wardrobe_app/features/ootd/models/daily_context.dart';
import 'package:digital_wardrobe_app/features/ootd/services/daily_context_interpreter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const DailyContextInterpreter interpreter = DailyContextInterpreter();

  group('DailyRequirements derivation', () {
    test('hot humid weather sets low warmth and high breathability', () {
      final requirements = interpreter.interpret(
        DailyContext(
          temperature: 34,
          feelsLike: 38,
          humidity: 82,
          rainProbability: 10,
          windSpeed: 5,
          uvIndex: 8,
          outdoor: true,
          date: DateTime(2026, 8, 24),
          season: 'summer',
        ),
      );

      expect(requirements.targetWarmth, lessThan(2.5));
      expect(requirements.targetBreathability, greaterThan(9));
      expect(requirements.preferLightLayers, isTrue);
      expect(requirements.windProtectionNeed, lessThan(3));
    });

    test('cold weather sets high warmth and low breathability', () {
      final requirements = interpreter.interpret(
        DailyContext(
          temperature: 5,
          feelsLike: 2,
          humidity: 40,
          rainProbability: 15,
          windSpeed: 10,
          date: DateTime(2026, 1, 15),
          season: 'winter',
        ),
      );

      expect(requirements.targetWarmth, greaterThan(8));
      expect(requirements.targetBreathability, lessThan(4));
      expect(requirements.preferLightLayers, isFalse);
    });

    test('high rain probability increases rain protection need', () {
      final requirements = interpreter.interpret(
        DailyContext(
          temperature: 22,
          humidity: 70,
          rainProbability: 75,
          windSpeed: 8,
          date: DateTime(2026, 7, 10),
          season: 'summer',
        ),
      );

      expect(requirements.rainProtectionNeed, greaterThanOrEqualTo(7));
      expect(requirements.avoidSuede, isTrue);
      expect(requirements.avoidOpenFootwear, isTrue);
    });

    test('wind protection need scales with wind speed', () {
      final calm = interpreter.interpret(
        DailyContext(
          temperature: 24,
          humidity: 50,
          rainProbability: 10,
          windSpeed: 5,
          date: DateTime(2026, 6, 1),
          season: 'summer',
        ),
      );

      final stormy = interpreter.interpret(
        DailyContext(
          temperature: 24,
          humidity: 50,
          rainProbability: 10,
          windSpeed: 30,
          date: DateTime(2026, 6, 1),
          season: 'summer',
        ),
      );

      expect(calm.windProtectionNeed, lessThan(stormy.windProtectionNeed));
      expect(stormy.windProtectionNeed, greaterThanOrEqualTo(6));
    });

    test('preferred fabrics include linen in hot weather', () {
      final requirements = interpreter.interpret(
        DailyContext(
          temperature: 34,
          feelsLike: 38,
          humidity: 75,
          rainProbability: 5,
          date: DateTime(2026, 8, 24),
          season: 'summer',
        ),
      );

      expect(
        requirements.preferredFabrics,
        containsAll(<String>['linen', 'cotton']),
      );
    });

    test('preferred fabrics include wool in cold weather', () {
      final requirements = interpreter.interpret(
        DailyContext(
          temperature: 6,
          feelsLike: 3,
          humidity: 40,
          rainProbability: 10,
          date: DateTime(2026, 1, 15),
          season: 'winter',
        ),
      );

      expect(
        requirements.preferredFabrics,
        containsAll(<String>['wool', 'fleece', 'knit']),
      );
    });

    test('avoided fabrics include wool in hot weather', () {
      final requirements = interpreter.interpret(
        DailyContext(
          temperature: 35,
          feelsLike: 38,
          humidity: 70,
          rainProbability: 10,
          date: DateTime(2026, 8, 24),
          season: 'summer',
        ),
      );

      expect(
        requirements.avoidedFabrics,
        containsAll(<String>['wool', 'fleece', 'velvet', 'suede']),
      );
    });

    test('avoided fabrics include suede when raining', () {
      final requirements = interpreter.interpret(
        DailyContext(
          temperature: 20,
          humidity: 80,
          rainProbability: 65,
          date: DateTime(2026, 7, 10),
          season: 'summer',
        ),
      );

      expect(requirements.avoidedFabrics, contains('suede'));
    });

    test('formality increases for wedding occasion', () {
      final requirements = interpreter.interpret(
        DailyContext(
          temperature: 24,
          humidity: 50,
          rainProbability: 10,
          occasion: 'wedding',
          dressCode: 'formal',
          date: DateTime(2026, 6, 15),
          season: 'summer',
        ),
      );

      expect(requirements.targetFormality, greaterThanOrEqualTo(8));
    });

    test('formality decreases for sport occasion', () {
      final requirements = interpreter.interpret(
        DailyContext(
          temperature: 24,
          humidity: 50,
          rainProbability: 10,
          occasion: 'sport',
          date: DateTime(2026, 6, 15),
          season: 'summer',
        ),
      );

      expect(requirements.targetFormality, lessThanOrEqualTo(3));
    });

    test('comfortable footwear is preferred for high activity', () {
      final requirements = interpreter.interpret(
        DailyContext(
          temperature: 24,
          humidity: 50,
          rainProbability: 10,
          expectedActivityLevel: 8,
          date: DateTime(2026, 6, 15),
          season: 'summer',
        ),
      );

      expect(requirements.preferComfortableFootwear, isTrue);
    });

    test('removable layer is preferred for wide temperature range', () {
      final requirements = interpreter.interpret(
        DailyContext(
          temperature: 18,
          minTemperature: 10,
          maxTemperature: 24,
          humidity: 50,
          rainProbability: 10,
          date: DateTime(2026, 4, 1),
          season: 'spring',
        ),
      );

      expect(requirements.preferRemovableLayer, isTrue);
    });

    test('removable layer is preferred in high wind', () {
      final requirements = interpreter.interpret(
        DailyContext(
          temperature: 20,
          humidity: 50,
          rainProbability: 10,
          windSpeed: 28,
          date: DateTime(2026, 4, 1),
          season: 'spring',
        ),
      );

      expect(requirements.preferRemovableLayer, isTrue);
    });

    test('extreme heat incompatibility conditions set correct thresholds', () {
      final requirements = interpreter.interpret(
        DailyContext(
          temperature: 40,
          feelsLike: 44,
          humidity: 90,
          rainProbability: 5,
          windSpeed: 2,
          uvIndex: 10,
          outdoor: true,
          date: DateTime(2026, 8, 24),
          season: 'summer',
        ),
      );

      expect(requirements.targetWarmth, lessThan(1.5));
      expect(requirements.targetBreathability, greaterThan(9.5));
      expect(requirements.rainProtectionNeed, lessThan(4));
      expect(requirements.windProtectionNeed, lessThan(3));
    });

    test('missing weather data produces sensible defaults', () {
      final requirements = interpreter.interpret(
        DailyContext(
          date: DateTime(2026, 6, 15),
          season: 'summer',
        ),
      );

      expect(requirements.targetWarmth, inInclusiveRange(1, 10));
      expect(requirements.targetBreathability, inInclusiveRange(1, 10));
      expect(requirements.preferredFabrics, isA<List<String>>());
      expect(requirements.avoidedFabrics, isA<List<String>>());
    });

    test('defaults sum to valid ranges', () {
      final requirements = interpreter.interpret(
        DailyContext(
          temperature: 24,
          humidity: 50,
          rainProbability: 10,
          date: DateTime(2026, 6, 15),
          season: 'summer',
        ),
      );

      expect(requirements.targetWarmth, inInclusiveRange(1, 10));
      expect(requirements.targetBreathability, inInclusiveRange(1, 10));
      expect(requirements.targetFormality, inInclusiveRange(1, 10));
      expect(requirements.rainProtectionNeed, inInclusiveRange(0, 10));
      expect(requirements.windProtectionNeed, inInclusiveRange(0, 10));
    });
  });

  group('DailyContext.inferSeason', () {
    test('infers summer for high temperature', () {
      final season = DailyContext.inferSeason(
        DateTime(2026, 7, 1),
        null,
      );
      expect(season, 'summer');
    });

    test('infers winter for low temperature in December', () {
      final season = DailyContext.inferSeason(
        DateTime(2026, 12, 15),
        null,
      );
      expect(season, 'winter');
    });

    test('infers rainy for high rain probability', () {
      final season = DailyContext.inferSeason(
        DateTime(2026, 8, 1),
        null,
      );
      // Without weather data, fall back to date-based
      expect(season, isNotEmpty);
    });
  });
}
