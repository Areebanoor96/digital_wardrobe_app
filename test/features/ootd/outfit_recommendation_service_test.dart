import 'package:digital_wardrobe_app/data/models/garment.dart';
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
    LaundryStatus laundryStatus = LaundryStatus.clean,
    bool isArchived = false,
    DateTime? lastWornDate,
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
    );
  }

  group('OOTD eligibility', () {
    test('archived garments are never recommended', () {
      final Garment archived = garment(
        id: 'archived',
        name: 'Archived Shirt',
        category: GarmentCategory.top,
        isArchived: true,
      );

      final Garment available = garment(
        id: 'available',
        name: 'Available Dress',
        category: GarmentCategory.dress,
      );

      final OutfitRecommendation result = service.recommend(
        allGarments: <Garment>[archived, available],
        recentlyWornGarmentIds: const <String>{},
      );

      expect(
        result.garments.any((Garment item) => item.id == archived.id),
        isFalse,
      );
    });

    test('dirty garments are never recommended', () {
      final Garment dirtyShoes = garment(
        id: 'dirty-shoes',
        name: 'Dirty Shoes',
        category: GarmentCategory.shoe,
        laundryStatus: LaundryStatus.dirty,
      );

      final Garment dress = garment(
        id: 'dress',
        name: 'Black Dress',
        category: GarmentCategory.dress,
      );

      final OutfitRecommendation result = service.recommend(
        allGarments: <Garment>[dress, dirtyShoes],
        recentlyWornGarmentIds: const <String>{},
      );

      expect(
        result.garments.any((Garment item) => item.id == dirtyShoes.id),
        isFalse,
      );
    });
  });

  group('OOTD hero selection', () {
    test('recently worn garment is deprioritized as hero', () {
      final Garment recentTop = garment(
        id: 'recent',
        name: 'Recently Worn Top',
        category: GarmentCategory.top,
        lastWornDate: DateTime.now(),
      );

      final Garment freshTop = garment(
        id: 'fresh',
        name: 'Fresh Top',
        category: GarmentCategory.top,
        lastWornDate: DateTime.now().subtract(const Duration(days: 30)),
      );

      final Garment bottom = garment(
        id: 'bottom',
        name: 'Black Trousers',
        category: GarmentCategory.bottom,
      );

      final OutfitRecommendation result = service.recommend(
        allGarments: <Garment>[recentTop, freshTop, bottom],
        recentlyWornGarmentIds: <String>{recentTop.id},
      );

      expect(result.heroGarment?.id, freshTop.id);
    });

    test('hero garment only appears once', () {
      final Garment top = garment(
        id: 'hero',
        name: 'White Shirt',
        category: GarmentCategory.top,
      );

      final Garment bottom = garment(
        id: 'bottom',
        name: 'Black Trousers',
        category: GarmentCategory.bottom,
      );

      final OutfitRecommendation result = service.recommend(
        allGarments: <Garment>[top, bottom],
        recentlyWornGarmentIds: const <String>{},
      );

      final int heroCount = result.garments
          .where((Garment item) => item.id == result.heroGarment?.id)
          .length;

      expect(heroCount, 1);
    });
  });

  group('OOTD context intelligence', () {
    test('occasion influences hero selection', () {
      final Garment weddingDress = garment(
        id: 'wedding',
        name: 'Wedding Dress',
        category: GarmentCategory.dress,
        occasions: const <String>['wedding'],
      );

      final Garment casualDress = garment(
        id: 'casual',
        name: 'Casual Dress',
        category: GarmentCategory.dress,
        occasions: const <String>['casual'],
      );

      final OutfitRecommendation result = service.recommend(
        allGarments: <Garment>[casualDress, weddingDress],
        recentlyWornGarmentIds: const <String>{},
        context: const OutfitContext(occasion: 'wedding'),
      );

      expect(result.heroGarment?.id, weddingDress.id);
    });

    test('season influences hero selection', () {
      final Garment summerDress = garment(
        id: 'summer',
        name: 'Summer Dress',
        category: GarmentCategory.dress,
        seasons: const <String>['summer'],
      );

      final Garment winterDress = garment(
        id: 'winter',
        name: 'Winter Dress',
        category: GarmentCategory.dress,
        seasons: const <String>['winter'],
      );

      final OutfitRecommendation result = service.recommend(
        allGarments: <Garment>[summerDress, winterDress],
        recentlyWornGarmentIds: const <String>{},
        context: const OutfitContext(season: 'winter'),
      );

      expect(result.heroGarment?.id, winterDress.id);
    });

    test('mood influences hero selection', () {
      final Garment relaxedDress = garment(
        id: 'relaxed',
        name: 'Relaxed Dress',
        category: GarmentCategory.dress,
        moods: const <String>['relaxed'],
      );

      final Garment elegantDress = garment(
        id: 'elegant',
        name: 'Elegant Dress',
        category: GarmentCategory.dress,
        moods: const <String>['elegant'],
      );

      final OutfitRecommendation result = service.recommend(
        allGarments: <Garment>[relaxedDress, elegantDress],
        recentlyWornGarmentIds: const <String>{},
        context: const OutfitContext(mood: 'elegant'),
      );

      expect(result.heroGarment?.id, elegantDress.id);
    });
  });

  group('OOTD result safety', () {
    test('score always stays between 0 and 100', () {
      final Garment top = garment(
        id: 'top',
        name: 'White Shirt',
        category: GarmentCategory.top,
        occasions: const <String>['wedding'],
        seasons: const <String>['winter'],
        moods: const <String>['elegant'],
        colorHex: '#FFFFFF',
      );

      final Garment bottom = garment(
        id: 'bottom',
        name: 'Black Trousers',
        category: GarmentCategory.bottom,
        occasions: const <String>['wedding'],
        seasons: const <String>['winter'],
        moods: const <String>['elegant'],
        colorHex: '#000000',
      );

      final OutfitRecommendation result = service.recommend(
        allGarments: <Garment>[top, bottom],
        recentlyWornGarmentIds: const <String>{},
        context: const OutfitContext(
          occasion: 'wedding',
          season: 'winter',
          mood: 'elegant',
        ),
      );

      expect(result.score, inInclusiveRange(0, 100));
    });

    test('empty wardrobe returns safe empty result', () {
      final OutfitRecommendation result = service.recommend(
        allGarments: const <Garment>[],
        recentlyWornGarmentIds: const <String>{},
      );

      expect(result.garments, isEmpty);
      expect(result.score, 0);
      expect(result.reason, isNotEmpty);
    });

    test('wardrobe containing only unavailable garments is safe', () {
      final Garment dirty = garment(
        id: 'dirty',
        name: 'Dirty Shirt',
        category: GarmentCategory.top,
        laundryStatus: LaundryStatus.dirty,
      );

      final Garment archived = garment(
        id: 'archived',
        name: 'Archived Trousers',
        category: GarmentCategory.bottom,
        isArchived: true,
      );

      final OutfitRecommendation result = service.recommend(
        allGarments: <Garment>[dirty, archived],
        recentlyWornGarmentIds: const <String>{},
      );

      expect(result.garments, isEmpty);
      expect(result.score, 0);
    });
  });
}
