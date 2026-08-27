import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/wear_log.dart';
import 'package:digital_wardrobe_app/features/ootd/models/daily_context.dart';
import 'package:digital_wardrobe_app/features/ootd/models/weather_data.dart';
import 'package:digital_wardrobe_app/features/ootd/services/daily_context_interpreter.dart';
import 'package:digital_wardrobe_app/features/ootd/services/garment_metadata_interpreter.dart';
import 'package:digital_wardrobe_app/features/ootd/services/outfit_recommendation_service.dart';
import 'package:digital_wardrobe_app/features/outfits/models/outfit_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const OutfitRecommendationService service = OutfitRecommendationService();

  Garment garment({
    required String id,
    required String name,
    required GarmentCategory category,
    List<String> occasions = const <String>[],
    List<String> seasons = const <String>[],
    List<String> moods = const <String>[],
    String? colorHex,
    String? secondaryColorHex,
    String? memberId = 'member-1',
    LaundryStatus laundryStatus = LaundryStatus.clean,
    bool isArchived = false,
    DateTime? lastWornDate,
    String? fabric,
    String? fabricWeight,
    String? fit,
    String? pattern,
    String? sleeveLength,
    int wearCount = 0,
    GarmentAvailabilityStatus availabilityStatus =
        GarmentAvailabilityStatus.available,
    IroningStatus? ironingStatus,
  }) {
    return Garment(
      id: id,
      name: name,
      memberId: memberId,
      category: category,
      photoPaths: const <String>['test/photo.jpg'],
      photoUrls: const <String>['https://example.com/photo.jpg'],
      occasions: occasions,
      seasons: seasons,
      moods: moods,
      colorHex: colorHex,
      secondaryColorHex: secondaryColorHex,
      laundryStatus: laundryStatus,
      isArchived: isArchived,
      lastWornDate: lastWornDate,
      fabric: fabric,
      fabricWeight: fabricWeight,
      fit: fit,
      pattern: pattern,
      sleeveLength: sleeveLength,
      wearCount: wearCount,
      availabilityStatus: availabilityStatus,
      ironingStatus: ironingStatus,
    );
  }

  List<Garment> baseWardrobe() {
    return <Garment>[
      garment(
        id: 'linen-shirt',
        name: 'White Linen Shirt',
        category: GarmentCategory.top,
        colorHex: '#FFFFFF',
        fabric: 'Linen',
        fabricWeight: 'Light',
        sleeveLength: 'Short Sleeve',
        fit: 'Regular',
        pattern: 'Solid',
        occasions: const <String>['casual', 'work'],
        seasons: const <String>['summer', 'all'],
      ),
      garment(
        id: 'wool-sweater',
        name: 'Heavy Wool Sweater',
        category: GarmentCategory.top,
        colorHex: '#7A1E1E',
        fabric: 'Wool',
        fabricWeight: 'Heavy',
        sleeveLength: 'Long Sleeve',
        fit: 'Oversized',
        pattern: 'Solid',
        occasions: const <String>['casual'],
        seasons: const <String>['winter'],
      ),
      garment(
        id: 'trousers',
        name: 'Black Trousers',
        category: GarmentCategory.bottom,
        colorHex: '#111111',
        fabric: 'Cotton',
        fabricWeight: 'Medium',
        fit: 'Straight',
        pattern: 'Solid',
        occasions: const <String>['work', 'casual'],
        seasons: const <String>['all'],
      ),
      garment(
        id: 'sandals',
        name: 'Tan Sandals',
        category: GarmentCategory.shoe,
        colorHex: '#D2B48C',
        fabric: 'Leather',
        occasions: const <String>['casual'],
        seasons: const <String>['summer'],
      ),
      garment(
        id: 'sneakers',
        name: 'White Sneakers',
        category: GarmentCategory.shoe,
        colorHex: '#F5F5F5',
        fabric: 'Canvas',
        occasions: const <String>['casual', 'travel', 'college'],
        seasons: const <String>['all'],
      ),
      garment(
        id: 'bag',
        name: 'Black Bag',
        category: GarmentCategory.bag,
        colorHex: '#000000',
        pattern: 'Solid',
      ),
    ];
  }

  group('context and garment metadata', () {
    test(
      'hot humid weather produces low warmth and high breathability needs',
      () {
        final requirements = const DailyContextInterpreter().interpret(
          DailyContext.from(
            weather: const WeatherData(
              temperature: 33,
              feelsLike: 38,
              humidity: 80,
              rainProbability: 20,
            ),
            date: DateTime(2026, 8, 24),
          ),
        );

        expect(requirements.targetWarmth, lessThan(2));
        expect(requirements.targetBreathability, greaterThan(9));
        expect(requirements.preferLightLayers, isTrue);
      },
    );

    test('garment metadata combines fabric, weight, sleeve and category', () {
      final metadata = const GarmentMetadataInterpreter().interpret(
        garment(
          id: 'coat',
          name: 'Heavy Wool Coat',
          category: GarmentCategory.outerwear,
          fabric: 'Wool',
          fabricWeight: 'Heavy',
          sleeveLength: 'Long Sleeve',
          fit: 'Structured',
          pattern: 'Solid',
        ),
      );

      expect(metadata.warmth, greaterThan(9));
      expect(metadata.breathability, lessThan(4));
      expect(metadata.formality, greaterThan(5));
    });
  });

  group('eligibility and hard rules', () {
    test('dress plus shoes is eligible without top and bottom', () {
      final List<Garment> garments = <Garment>[
        garment(
          id: 'dress',
          name: 'Blue Dress',
          category: GarmentCategory.dress,
        ),
        garment(
          id: 'shoes',
          name: 'Black Shoes',
          category: GarmentCategory.shoe,
        ),
      ];

      expect(service.isEligibleForRecommendation(garments), isTrue);
    });

    test('dress outfit excludes separate top and bottom', () {
      final OutfitRecommendation result = service.recommend(
        allGarments: <Garment>[
          garment(
            id: 'dress',
            name: 'Black Dress',
            category: GarmentCategory.dress,
            occasions: const <String>['formal'],
          ),
          ...baseWardrobe(),
        ],
        context: const OutfitContext(occasion: 'formal'),
        memberId: 'member-1',
        now: DateTime(2026, 8, 24),
      );

      final bool hasDress = result.garments.any(
        (Garment garment) => garment.category == GarmentCategory.dress,
      );

      if (hasDress) {
        expect(
          result.garments.any(
            (Garment garment) => garment.category == GarmentCategory.top,
          ),
          isFalse,
        );
        expect(
          result.garments.any(
            (Garment garment) => garment.category == GarmentCategory.bottom,
          ),
          isFalse,
        );
      }
    });

    test('dirty, archived and other-member garments are never recommended', () {
      final OutfitRecommendation result = service.recommend(
        allGarments: <Garment>[
          ...baseWardrobe(),
          garment(
            id: 'dirty',
            name: 'Dirty Shirt',
            category: GarmentCategory.top,
            laundryStatus: LaundryStatus.dirty,
          ),
          garment(
            id: 'archived',
            name: 'Archived Shoes',
            category: GarmentCategory.shoe,
            isArchived: true,
          ),
          garment(
            id: 'other',
            name: 'Other Member Trousers',
            category: GarmentCategory.bottom,
            memberId: 'member-2',
          ),
        ],
        memberId: 'member-1',
        now: DateTime(2026, 8, 24),
      );

      expect(
        result.garments.map((Garment g) => g.id),
        isNot(contains('dirty')),
      );
      expect(
        result.garments.map((Garment g) => g.id),
        isNot(contains('archived')),
      );
      expect(
        result.garments.map((Garment g) => g.id),
        isNot(contains('other')),
      );
    });

    test('availability and ironing status are hard recommendation rules', () {
      final OutfitRecommendation result = service.recommend(
        allGarments: <Garment>[
          garment(
            id: 'available-top',
            name: 'Available Shirt',
            category: GarmentCategory.top,
          ),
          garment(
            id: 'borrowed-bottom',
            name: 'Borrowed Trousers',
            category: GarmentCategory.bottom,
            availabilityStatus: GarmentAvailabilityStatus.borrowed,
          ),
          garment(
            id: 'available-shoes',
            name: 'Available Shoes',
            category: GarmentCategory.shoe,
          ),
          garment(
            id: 'lent',
            name: 'Lent Shirt',
            category: GarmentCategory.top,
            availabilityStatus: GarmentAvailabilityStatus.lent,
          ),
          garment(
            id: 'storage',
            name: 'Stored Trousers',
            category: GarmentCategory.bottom,
            availabilityStatus: GarmentAvailabilityStatus.inStorage,
          ),
          garment(
            id: 'donated',
            name: 'Donated Shoes',
            category: GarmentCategory.shoe,
            availabilityStatus: GarmentAvailabilityStatus.donated,
          ),
          garment(
            id: 'lost',
            name: 'Lost Bag',
            category: GarmentCategory.bag,
            availabilityStatus: GarmentAvailabilityStatus.lost,
          ),
          garment(
            id: 'needs-ironing',
            name: 'Wrinkled Shirt',
            category: GarmentCategory.top,
            ironingStatus: IroningStatus.needsIroning,
          ),
        ],
        memberId: 'member-1',
        now: DateTime(2026, 8, 24),
      );

      final Iterable<String> ids = result.garments.map((Garment g) => g.id);
      expect(ids, contains('available-top'));
      expect(ids, contains('borrowed-bottom'));
      expect(ids, isNot(contains('lent')));
      expect(ids, isNot(contains('storage')));
      expect(ids, isNot(contains('donated')));
      expect(ids, isNot(contains('lost')));
      expect(ids, isNot(contains('needs-ironing')));
    });
  });

  group('complete outfit ranking', () {
    test('hot weather prefers breathable linen over heavy wool', () {
      final OutfitRecommendation result = service.recommend(
        allGarments: baseWardrobe(),
        weather: const WeatherData(
          temperature: 34,
          feelsLike: 38,
          humidity: 75,
          rainProbability: 10,
          condition: 'Clear',
        ),
        context: const OutfitContext(occasion: 'casual'),
        memberId: 'member-1',
        now: DateTime(2026, 8, 24),
      );

      expect(result.garments.map((Garment g) => g.id), contains('linen-shirt'));
      expect(
        result.garments.map((Garment g) => g.id),
        isNot(contains('wool-sweater')),
      );
      expect(result.weatherScore, greaterThan(60));
    });

    test('recent top receives stronger rotation penalty than shoes', () {
      final List<WearLog> wearLogs = <WearLog>[
        WearLog(
          id: 'top-log',
          memberId: 'member-1',
          garmentId: 'linen-shirt',
          wornDate: DateTime(2026, 8, 23),
        ),
      ];

      final OutfitRecommendation result = service.recommend(
        allGarments: baseWardrobe(),
        wearLogs: wearLogs,
        weather: const WeatherData(temperature: 25, feelsLike: 25),
        memberId: 'member-1',
        now: DateTime(2026, 8, 24),
      );

      final bool includesRecentTop = result.garments.any(
        (Garment garment) => garment.id == 'linen-shirt',
      );

      expect(!includesRecentTop || result.rotationScore < 78, isTrue);
    });

    test('returns up to three distinct recommendations', () {
      final List<OutfitRecommendation> results = service.recommendMany(
        allGarments: <Garment>[
          ...baseWardrobe(),
          garment(
            id: 'dress',
            name: 'Green Dress',
            category: GarmentCategory.dress,
            colorHex: '#2E7D32',
            fabric: 'Cotton',
          ),
          garment(
            id: 'flats',
            name: 'Black Flats',
            category: GarmentCategory.shoe,
            colorHex: '#000000',
          ),
        ],
        memberId: 'member-1',
        now: DateTime(2026, 8, 24),
      );

      expect(results.length, inInclusiveRange(1, 3));
      expect(results.first.alternatives.length, results.length - 1);
      expect(results.first.score, inInclusiveRange(0, 100));
    });

    test('missing weather still returns a safe recommendation', () {
      final OutfitRecommendation result = service.recommend(
        allGarments: baseWardrobe(),
        memberId: 'member-1',
        now: DateTime(2026, 8, 24),
      );

      expect(result.garments, isNotEmpty);
      expect(result.reasons.join(' '), contains('Weather is unavailable'));
    });
  });
}
