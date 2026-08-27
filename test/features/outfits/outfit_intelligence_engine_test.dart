import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/outfits/models/outfit_context.dart';
import 'package:digital_wardrobe_app/features/outfits/services/outfit_intelligence_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const OutfitIntelligenceEngine engine = OutfitIntelligenceEngine();

  Garment garment({
    required String id,
    required String name,
    required GarmentCategory category,
    List<String> occasions = const <String>[],
    List<String> seasons = const <String>[],
    List<String> moods = const <String>[],
    String? colorHex,
    LaundryStatus laundryStatus = LaundryStatus.clean,
    bool isArchived = false,
    DateTime? lastWornDate,
    GarmentAvailabilityStatus availabilityStatus =
        GarmentAvailabilityStatus.available,
    IroningStatus? ironingStatus,
  }) {
    return Garment(
      id: id,
      name: name,
      memberId: 'member-1',
      category: category,
      photoPaths: const <String>['test/photo.jpg'],
      photoUrls: const <String>['https://example.com/photo.jpg'],
      occasions: occasions,
      seasons: seasons,
      moods: moods,
      colorHex: colorHex,
      laundryStatus: laundryStatus,
      isArchived: isArchived,
      lastWornDate: lastWornDate,
      availabilityStatus: availabilityStatus,
      ironingStatus: ironingStatus,
    );
  }

  group('OutfitIntelligenceEngine eligibility', () {
    test('does not recommend archived garments', () {
      final Garment hero = garment(
        id: 'hero',
        name: 'White Shirt',
        category: GarmentCategory.top,
      );

      final Garment archivedBottom = garment(
        id: 'bottom',
        name: 'Black Trousers',
        category: GarmentCategory.bottom,
        isArchived: true,
      );

      final result = engine.recommend(
        garments: <Garment>[
          hero,
          archivedBottom,
        ],
        context: OutfitContext(
          heroGarment: hero,
        ),
      );

      expect(
        result.garments.any(
              (Garment item) => item.id == archivedBottom.id,
        ),
        isFalse,
      );
    });

    test('does not recommend dirty garments', () {
      final Garment hero = garment(
        id: 'hero',
        name: 'White Shirt',
        category: GarmentCategory.top,
      );

      final Garment dirtyBottom = garment(
        id: 'bottom',
        name: 'Black Trousers',
        category: GarmentCategory.bottom,
        laundryStatus: LaundryStatus.dirty,
      );

      final result = engine.recommend(
        garments: <Garment>[
          hero,
          dirtyBottom,
        ],
        context: OutfitContext(
          heroGarment: hero,
        ),
      );

      expect(
        result.garments.any(
              (Garment item) => item.id == dirtyBottom.id,
        ),
        isFalse,
      );
    });

    test('does not recommend unavailable or needs-ironing garments', () {
      final Garment hero = garment(
        id: 'hero',
        name: 'White Shirt',
        category: GarmentCategory.top,
      );

      final Garment borrowedBottom = garment(
        id: 'borrowed',
        name: 'Borrowed Trousers',
        category: GarmentCategory.bottom,
        availabilityStatus: GarmentAvailabilityStatus.borrowed,
      );

      final Garment lentBottom = garment(
        id: 'lent',
        name: 'Lent Trousers',
        category: GarmentCategory.bottom,
        availabilityStatus: GarmentAvailabilityStatus.lent,
      );

      final Garment needsIroning = garment(
        id: 'needs-ironing',
        name: 'Wrinkled Trousers',
        category: GarmentCategory.bottom,
        ironingStatus: IroningStatus.needsIroning,
      );

      final result = engine.recommend(
        garments: <Garment>[
          hero,
          borrowedBottom,
          lentBottom,
          needsIroning,
        ],
        context: OutfitContext(
          heroGarment: hero,
        ),
      );

      final Iterable<String> ids = result.garments.map(
        (Garment item) => item.id,
      );

      expect(ids, contains('borrowed'));
      expect(ids, isNot(contains('lent')));
      expect(ids, isNot(contains('needs-ironing')));
    });

    test('hero garment is not duplicated', () {
      final Garment hero = garment(
        id: 'hero',
        name: 'White Shirt',
        category: GarmentCategory.top,
      );

      final Garment bottom = garment(
        id: 'bottom',
        name: 'Black Trousers',
        category: GarmentCategory.bottom,
      );

      final result = engine.recommend(
        garments: <Garment>[
          hero,
          bottom,
        ],
        context: OutfitContext(
          heroGarment: hero,
        ),
      );

      final int heroCount = result.garments
          .where(
            (Garment item) => item.id == hero.id,
      )
          .length;

      expect(heroCount, 1);
    });
  });

  group('OutfitIntelligenceEngine composition', () {
    test('dress is not combined with top or bottom', () {
      final Garment dress = garment(
        id: 'dress',
        name: 'Black Dress',
        category: GarmentCategory.dress,
      );

      final Garment top = garment(
        id: 'top',
        name: 'White Shirt',
        category: GarmentCategory.top,
      );

      final Garment bottom = garment(
        id: 'bottom',
        name: 'Black Trousers',
        category: GarmentCategory.bottom,
      );

      final Garment shoes = garment(
        id: 'shoes',
        name: 'Black Heels',
        category: GarmentCategory.shoe,
      );

      final result = engine.recommend(
        garments: <Garment>[
          dress,
          top,
          bottom,
          shoes,
        ],
        context: OutfitContext(
          heroGarment: dress,
        ),
      );

      expect(
        result.garments.any(
              (Garment item) => item.category == GarmentCategory.top,
        ),
        isFalse,
      );

      expect(
        result.garments.any(
              (Garment item) => item.category == GarmentCategory.bottom,
        ),
        isFalse,
      );

      expect(
        result.garments.any(
              (Garment item) => item.category == GarmentCategory.shoe,
        ),
        isTrue,
      );
    });

    test('top can be combined with bottom and shoes', () {
      final Garment top = garment(
        id: 'top',
        name: 'White Shirt',
        category: GarmentCategory.top,
      );

      final Garment bottom = garment(
        id: 'bottom',
        name: 'Black Trousers',
        category: GarmentCategory.bottom,
      );

      final Garment shoes = garment(
        id: 'shoes',
        name: 'Black Shoes',
        category: GarmentCategory.shoe,
      );

      final result = engine.recommend(
        garments: <Garment>[
          top,
          bottom,
          shoes,
        ],
        context: OutfitContext(
          heroGarment: top,
        ),
      );

      expect(
        result.garments.any(
              (Garment item) => item.category == GarmentCategory.bottom,
        ),
        isTrue,
      );

      expect(
        result.garments.any(
              (Garment item) => item.category == GarmentCategory.shoe,
        ),
        isTrue,
      );
    });
  });

  group('Outfit intelligence scoring', () {
    test('matching context produces a higher score', () {
      final Garment hero = garment(
        id: 'hero',
        name: 'White Blazer',
        category: GarmentCategory.outerwear,
        colorHex: '#FFFFFF',
      );

      final Garment strongMatch = garment(
        id: 'strong',
        name: 'Elegant Black Trousers',
        category: GarmentCategory.bottom,
        occasions: const <String>['Wedding'],
        seasons: const <String>['Winter'],
        moods: const <String>['Elegant'],
        colorHex: '#000000',
      );

      final Garment weakMatch = garment(
        id: 'weak',
        name: 'Blue Jeans',
        category: GarmentCategory.bottom,
        occasions: const <String>['Everyday'],
        seasons: const <String>['Summer'],
        moods: const <String>['Relaxed'],
        colorHex: '#0000FF',
      );

      const OutfitContext context = OutfitContext(
        occasion: 'Wedding',
        season: 'Winter',
        mood: 'Elegant',
      );

      final matchingResult = engine.recommend(
        garments: <Garment>[
          hero,
          strongMatch,
        ],
        context: context.copyWith(heroGarment: hero),
      );

      final weakResult = engine.recommend(
        garments: <Garment>[
          hero,
          weakMatch,
        ],
        context: context.copyWith(heroGarment: hero),
      );

      expect(
        matchingResult.score,
        greaterThan(weakResult.score),
      );
    });

    test('recommendation score stays between 0 and 100', () {
      final Garment hero = garment(
        id: 'hero',
        name: 'White Blazer',
        category: GarmentCategory.outerwear,
      );

      final Garment bottom = garment(
        id: 'bottom',
        name: 'Black Trousers',
        category: GarmentCategory.bottom,
        occasions: const <String>['Wedding'],
        seasons: const <String>['Winter'],
        moods: const <String>['Elegant'],
      );

      final result = engine.recommend(
        garments: <Garment>[
          hero,
          bottom,
        ],
        context: OutfitContext(
          heroGarment: hero,
          occasion: 'Wedding',
          season: 'Winter',
          mood: 'Elegant',
        ),
      );

      expect(result.score, inInclusiveRange(0, 100));
    });
  });

  group('OutfitIntelligenceEngine empty state', () {
    test('returns safe recommendation when nothing is available', () {
      final Garment archived = garment(
        id: 'archived',
        name: 'Archived Shirt',
        category: GarmentCategory.top,
        isArchived: true,
      );

      final result = engine.recommend(
        garments: <Garment>[
          archived,
        ],
        context: const OutfitContext(),
      );

      expect(result.garments, isEmpty);
      expect(result.score, 0);
      expect(result.reasons, isNotEmpty);
    });
  });
}
