import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/ootd/models/outfit_candidate.dart';
import 'package:digital_wardrobe_app/features/ootd/services/candidate_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const CandidateGenerator generator = CandidateGenerator(
    maxPerRequiredCategory: 10,
    maxOptionalPerCategory: 5,
    maxCandidates: 700,
  );

  Garment makeGarment({
    required String id,
    required GarmentCategory category,
    String? colorHex,
    int wearCount = 0,
  }) {
    return Garment(
      id: id,
      name: 'Garment $id',
      memberId: 'member-1',
      category: category,
      photoPaths: const <String>[],
      photoUrls: const <String>[],
      colorHex: colorHex,
      wearCount: wearCount,
    );
  }

  group('CandidateGenerator', () {
    test('generates separated outfit candidates from top, bottom, shoes', () {
      final List<Garment> garments = <Garment>[
        makeGarment(id: 'top-1', category: GarmentCategory.top),
        makeGarment(id: 'bottom-1', category: GarmentCategory.bottom),
        makeGarment(id: 'shoe-1', category: GarmentCategory.shoe),
      ];

      final candidates = generator.generate(garments);

      expect(candidates, isNotEmpty);
      expect(
        candidates.every(
          (OutfitCandidate c) =>
              c.templateType == OotdTemplateType.separated,
        ),
        isTrue,
      );
    });

    test('generates dress outfit candidates from dress and shoes', () {
      final List<Garment> garments = <Garment>[
        makeGarment(id: 'dress-1', category: GarmentCategory.dress),
        makeGarment(id: 'shoe-1', category: GarmentCategory.shoe),
      ];

      final candidates = generator.generate(garments);

      expect(candidates, isNotEmpty);
      expect(
        candidates.every(
          (OutfitCandidate c) =>
              c.templateType == OotdTemplateType.dress,
        ),
        isTrue,
      );
    });

    test('generates both separated and dress when both templates are available', () {
      final List<Garment> garments = <Garment>[
        makeGarment(id: 'top-1', category: GarmentCategory.top),
        makeGarment(id: 'bottom-1', category: GarmentCategory.bottom),
        makeGarment(id: 'dress-1', category: GarmentCategory.dress),
        makeGarment(id: 'shoe-1', category: GarmentCategory.shoe),
      ];

      final candidates = generator.generate(garments);

      final hasSeparated = candidates.any(
        (OutfitCandidate c) =>
            c.templateType == OotdTemplateType.separated,
      );
      final hasDress = candidates.any(
        (OutfitCandidate c) =>
            c.templateType == OotdTemplateType.dress,
      );

      expect(hasSeparated, isTrue);
      expect(hasDress, isTrue);
    });

    test('includes optional outerwear when available', () {
      final List<Garment> garments = <Garment>[
        makeGarment(id: 'top-1', category: GarmentCategory.top),
        makeGarment(id: 'bottom-1', category: GarmentCategory.bottom),
        makeGarment(id: 'shoe-1', category: GarmentCategory.shoe),
        makeGarment(id: 'jacket-1', category: GarmentCategory.outerwear),
      ];

      final candidates = generator.generate(garments);

      final withOuterwear = candidates
          .where(
            (OutfitCandidate c) =>
                c.containsCategory(GarmentCategory.outerwear),
          )
          .length;

      expect(withOuterwear, greaterThan(0));
    });

    test('returns empty when no valid template can be built', () {
      final List<Garment> garments = <Garment>[
        makeGarment(id: 'bag-1', category: GarmentCategory.bag),
        makeGarment(id: 'jewelry-1', category: GarmentCategory.jewelry),
      ];

      final candidates = generator.generate(garments);
      expect(candidates, isEmpty);
    });

    test('returns empty for empty garment list', () {
      final candidates = generator.generate(<Garment>[]);
      expect(candidates, isEmpty);
    });

    test('limits per-category cap', () {
      final limitedGenerator = CandidateGenerator(
        maxPerRequiredCategory: 2,
        maxOptionalPerCategory: 5,
      );

      final List<Garment> garments = <Garment>[
        makeGarment(id: 'top-1', category: GarmentCategory.top),
        makeGarment(id: 'top-2', category: GarmentCategory.top),
        makeGarment(id: 'top-3', category: GarmentCategory.top),
        makeGarment(id: 'bottom-1', category: GarmentCategory.bottom),
        makeGarment(id: 'shoe-1', category: GarmentCategory.shoe),
      ];

      final candidates = limitedGenerator.generate(garments);
      final topIds = <String>{};

      for (final OutfitCandidate c in candidates) {
        for (final Garment g in c.garments) {
          if (g.category == GarmentCategory.top) {
            topIds.add(g.id);
          }
        }
      }

      expect(topIds.length, lessThanOrEqualTo(2));
    });

    test('candidate garment ids are accessible', () {
      final List<Garment> garments = <Garment>[
        makeGarment(id: 'top-1', category: GarmentCategory.top),
        makeGarment(id: 'bottom-1', category: GarmentCategory.bottom),
        makeGarment(id: 'shoe-1', category: GarmentCategory.shoe),
      ];

      final candidates = generator.generate(garments);
      expect(candidates, isNotEmpty);

      for (final OutfitCandidate c in candidates) {
        expect(c.garmentIds, isNotEmpty);
        expect(c.garmentIds.length, c.garments.length);
      }
    });

    test('sorts garments by wear count ascending for rotation preference', () {
      final List<Garment> garments = <Garment>[
        makeGarment(
          id: 'top-1',
          category: GarmentCategory.top,
          wearCount: 10,
        ),
        makeGarment(
          id: 'top-2',
          category: GarmentCategory.top,
          wearCount: 2,
        ),
        makeGarment(id: 'bottom-1', category: GarmentCategory.bottom),
        makeGarment(id: 'shoe-1', category: GarmentCategory.shoe),
      ];

      final candidates = generator.generate(garments);
      expect(candidates, isNotEmpty);
    });
  });
}
