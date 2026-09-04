import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/wear_log.dart';
import 'package:digital_wardrobe_app/features/ootd/models/weather_data.dart';
import 'package:digital_wardrobe_app/features/ootd/services/outfit_recommendation_service.dart';
import 'package:digital_wardrobe_app/features/outfits/models/outfit_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const OutfitRecommendationService service = OutfitRecommendationService();

  Garment makeGarment({
    required String id,
    required String name,
    required GarmentCategory category,
    String? colorHex,
    List<String> occasions = const <String>[],
    List<String> seasons = const <String>[],
    String? fabric,
    String? fabricWeight,
    String? fit,
    String? pattern,
    String? sleeveLength,
    int wearCount = 0,
  }) {
    return Garment(
      id: id,
      name: name,
      memberId: 'member-1',
      category: category,
      photoPaths: const <String>[],
      photoUrls: const <String>[],
      colorHex: colorHex,
      occasions: occasions,
      seasons: seasons,
      fabric: fabric,
      fabricWeight: fabricWeight,
      fit: fit,
      pattern: pattern,
      sleeveLength: sleeveLength,
      wearCount: wearCount,
    );
  }

  List<Garment> fullWardrobe() {
    return <Garment>[
      makeGarment(
        id: 'top-1',
        name: 'White Cotton Tee',
        category: GarmentCategory.top,
        colorHex: '#FFFFFF',
        fabric: 'Cotton',
        fabricWeight: 'Light',
        fit: 'Regular',
        pattern: 'Solid',
        sleeveLength: 'Short Sleeve',
        occasions: const <String>['casual', 'work'],
        seasons: const <String>['all'],
      ),
      makeGarment(
        id: 'bottom-1',
        name: 'Blue Denim Jeans',
        category: GarmentCategory.bottom,
        colorHex: '#1E3A8A',
        fabric: 'Denim',
        fit: 'Straight',
        pattern: 'Solid',
        occasions: const <String>['casual'],
        seasons: const <String>['all'],
      ),
      makeGarment(
        id: 'shoe-1',
        name: 'White Sneakers',
        category: GarmentCategory.shoe,
        colorHex: '#F5F5F5',
        fabric: 'Canvas',
        occasions: const <String>['casual', 'travel'],
        seasons: const <String>['all'],
      ),
      makeGarment(
        id: 'shirt-1',
        name: 'Formal White Shirt',
        category: GarmentCategory.top,
        colorHex: '#FFFFFF',
        fabric: 'Cotton',
        fabricWeight: 'Medium',
        fit: 'Tailored',
        pattern: 'Solid',
        sleeveLength: 'Long Sleeve',
        occasions: const <String>['work', 'formal'],
        seasons: const <String>['all'],
      ),
      makeGarment(
        id: 'trousers-1',
        name: 'Black Formal Trousers',
        category: GarmentCategory.bottom,
        colorHex: '#111111',
        fabric: 'Wool',
        fit: 'Tailored',
        pattern: 'Solid',
        occasions: const <String>['work', 'formal'],
        seasons: const <String>['all'],
      ),
      makeGarment(
        id: 'loafers-1',
        name: 'Black Leather Loafers',
        category: GarmentCategory.shoe,
        colorHex: '#000000',
        fabric: 'Leather',
        occasions: const <String>['work', 'formal'],
        seasons: const <String>['all'],
      ),
    ];
  }

  List<WearLog> wearAllRecently() {
    final DateTime now = DateTime(2026, 6, 15);
    return fullWardrobe()
        .map(
          (Garment g) => WearLog(
            id: 'log-${g.id}',
            memberId: 'member-1',
            garmentId: g.id,
            wornDate: now.subtract(const Duration(days: 1)),
          ),
        )
        .toList();
  }

  group('full ranking pipeline', () {
    test('formal occasion prefers formal garments', () {
      final result = service.recommend(
        allGarments: fullWardrobe(),
        context: const OutfitContext(occasion: 'formal'),
        memberId: 'member-1',
        now: DateTime(2026, 6, 15),
      );

      final Iterable<String> ids = result.garments.map((Garment g) => g.id);
      expect(ids, containsAll(<String>['shirt-1', 'trousers-1', 'loafers-1']));
    });

    test('hot weather prefers lighter breathable fabrics', () {
      final result = service.recommend(
        allGarments: fullWardrobe(),
        weather: const WeatherData(
          temperature: 36,
          feelsLike: 40,
          humidity: 80,
          rainProbability: 5,
        ),
        context: const OutfitContext(occasion: 'casual'),
        memberId: 'member-1',
        now: DateTime(2026, 8, 24),
      );

      final Iterable<String> ids = result.garments.map((Garment g) => g.id);
      expect(ids, contains('top-1'));
    });

    test('rain promotes avoided suede/open footwear rules', () {
      final result = service.recommend(
        allGarments: fullWardrobe(),
        weather: const WeatherData(
          temperature: 20,
          feelsLike: 20,
          rainProbability: 80,
        ),
        context: const OutfitContext(occasion: 'casual'),
        memberId: 'member-1',
        now: DateTime(2026, 7, 10),
      );

      expect(result.weatherScore, greaterThan(0));
    });

    test('empty wardrobe returns empty recommendation with guidance', () {
      final result = service.recommend(
        allGarments: <Garment>[],
        memberId: 'member-1',
        now: DateTime(2026, 6, 15),
      );

      expect(result.garments, isEmpty);
      expect(result.reason, contains('Add clean, available'));
    });

    test('wardrobe without a complete outfit is not eligible', () {
      final result = service.isEligibleForRecommendation(
        <Garment>[
          makeGarment(
            id: 'only-top',
            name: 'Only Top',
            category: GarmentCategory.top,
          ),
        ],
      );

      expect(result, isFalse);
    });

    test('recently worn all pieces still produces some recommendation', () {
      final result = service.recommend(
        allGarments: fullWardrobe(),
        wearLogs: wearAllRecently(),
        context: const OutfitContext(occasion: 'casual'),
        memberId: 'member-1',
        now: DateTime(2026, 6, 15),
      );

      expect(result.garments, isNotEmpty);
    });

    test('scores are within valid range for best match', () {
      final result = service.recommend(
        allGarments: fullWardrobe(),
        memberId: 'member-1',
        now: DateTime(2026, 6, 15),
      );

      expect(result.score, inInclusiveRange(0, 100));
      expect(result.weatherScore, inInclusiveRange(0, 100));
      expect(result.occasionScore, inInclusiveRange(0, 100));
      expect(result.colorScore, inInclusiveRange(0, 100));
      expect(result.styleScore, inInclusiveRange(0, 100));
    });
  });
}
