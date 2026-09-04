import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/ootd/models/daily_requirements.dart';
import 'package:digital_wardrobe_app/features/ootd/models/outfit_candidate.dart';
import 'package:digital_wardrobe_app/features/ootd/rules/hard_rule_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const HardRuleEngine engine = HardRuleEngine();

  Garment makeGarment({
    required String id,
    required GarmentCategory category,
    bool isArchived = false,
    LaundryStatus laundryStatus = LaundryStatus.clean,
    GarmentAvailabilityStatus availabilityStatus =
        GarmentAvailabilityStatus.available,
    IroningStatus? ironingStatus,
    String? fabric,
    String? fabricWeight,
    String? sleeveLength,
    String? name,
    String? memberId,
  }) {
    return Garment(
      id: id,
      name: name ?? 'Garment $id',
      memberId: memberId ?? 'member-1',
      category: category,
      photoPaths: const <String>[],
      photoUrls: const <String>[],
      isArchived: isArchived,
      laundryStatus: laundryStatus,
      availabilityStatus: availabilityStatus,
      ironingStatus: ironingStatus,
      fabric: fabric,
      fabricWeight: fabricWeight,
      sleeveLength: sleeveLength,
    );
  }

  OutfitCandidate separatedCandidate({
    List<Garment>? garments,
  }) {
    return OutfitCandidate(
      templateType: OotdTemplateType.separated,
      garments: garments ??
          <Garment>[
            makeGarment(id: 'top-1', category: GarmentCategory.top),
            makeGarment(id: 'bottom-1', category: GarmentCategory.bottom),
            makeGarment(id: 'shoe-1', category: GarmentCategory.shoe),
          ],
    );
  }

  OutfitCandidate dressCandidate({
    List<Garment>? garments,
  }) {
    return OutfitCandidate(
      templateType: OotdTemplateType.dress,
      garments: garments ??
          <Garment>[
            makeGarment(id: 'dress-1', category: GarmentCategory.dress),
            makeGarment(id: 'shoe-1', category: GarmentCategory.shoe),
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

  group('HardRuleEngine', () {
    test('accepts valid separated candidate', () {
      final result = engine.evaluate(
        candidate: separatedCandidate(),
        requirements: defaultRequirements,
      );

      expect(result.accepted, isTrue);
      expect(result.reason, isNull);
    });

    test('accepts valid dress candidate', () {
      final result = engine.evaluate(
        candidate: dressCandidate(),
        requirements: defaultRequirements,
      );

      expect(result.accepted, isTrue);
      expect(result.reason, isNull);
    });

    test('rejects empty candidate', () {
      final result = engine.evaluate(
        candidate: OutfitCandidate(
          templateType: OotdTemplateType.separated,
          garments: const <Garment>[],
        ),
        requirements: defaultRequirements,
      );

      expect(result.accepted, isFalse);
      expect(result.reason, contains('empty'));
    });

    test('rejects candidate with duplicate garment', () {
      final top = makeGarment(id: 'top-1', category: GarmentCategory.top);
      final result = engine.evaluate(
        candidate: OutfitCandidate(
          templateType: OotdTemplateType.separated,
          garments: <Garment>[
            top,
            top,
            makeGarment(id: 'shoe-1', category: GarmentCategory.shoe),
          ],
        ),
        requirements: defaultRequirements,
      );

      expect(result.accepted, isFalse);
      expect(result.reason, contains('duplicate'));
    });

    test('rejects archived garment', () {
      final result = engine.evaluate(
        candidate: separatedCandidate(
          garments: <Garment>[
            makeGarment(
              id: 'top-1',
              category: GarmentCategory.top,
              isArchived: true,
            ),
            makeGarment(id: 'bottom-1', category: GarmentCategory.bottom),
            makeGarment(id: 'shoe-1', category: GarmentCategory.shoe),
          ],
        ),
        requirements: defaultRequirements,
      );

      expect(result.accepted, isFalse);
      expect(result.reason, contains('archived'));
    });

    test('rejects dirty garment', () {
      final result = engine.evaluate(
        candidate: separatedCandidate(
          garments: <Garment>[
            makeGarment(id: 'top-1', category: GarmentCategory.top),
            makeGarment(id: 'bottom-1', category: GarmentCategory.bottom),
            makeGarment(
              id: 'shoe-1',
              category: GarmentCategory.shoe,
              laundryStatus: LaundryStatus.dirty,
            ),
          ],
        ),
        requirements: defaultRequirements,
      );

      expect(result.accepted, isFalse);
      expect(result.reason, contains('laundry'));
    });

    test('rejects garment that needs ironing', () {
      final result = engine.evaluate(
        candidate: separatedCandidate(
          garments: <Garment>[
            makeGarment(
              id: 'top-1',
              category: GarmentCategory.top,
              ironingStatus: IroningStatus.needsIroning,
            ),
            makeGarment(id: 'bottom-1', category: GarmentCategory.bottom),
            makeGarment(id: 'shoe-1', category: GarmentCategory.shoe),
          ],
        ),
        requirements: defaultRequirements,
      );

      expect(result.accepted, isFalse);
      expect(result.reason, contains('ironing'));
    });

    test('rejects lent garment', () {
      final result = engine.evaluate(
        candidate: separatedCandidate(
          garments: <Garment>[
            makeGarment(id: 'top-1', category: GarmentCategory.top),
            makeGarment(id: 'bottom-1', category: GarmentCategory.bottom),
            makeGarment(
              id: 'shoe-1',
              category: GarmentCategory.shoe,
              availabilityStatus: GarmentAvailabilityStatus.lent,
            ),
          ],
        ),
        requirements: defaultRequirements,
      );

      expect(result.accepted, isFalse);
      expect(result.reason, contains('unavailable'));
    });

    test('borrowed garment remains physically available', () {
      final result = engine.evaluate(
        candidate: separatedCandidate(
          garments: <Garment>[
            makeGarment(id: 'top-1', category: GarmentCategory.top),
            makeGarment(id: 'bottom-1', category: GarmentCategory.bottom),
            makeGarment(
              id: 'shoe-1',
              category: GarmentCategory.shoe,
              availabilityStatus: GarmentAvailabilityStatus.borrowed,
            ),
          ],
        ),
        requirements: defaultRequirements,
      );

      expect(result.accepted, isTrue);
    });

    test('rejects when wrong member', () {
      final result = engine.evaluate(
        candidate: separatedCandidate(
          garments: <Garment>[
            makeGarment(id: 'top-1', category: GarmentCategory.top),
            makeGarment(
              id: 'bottom-1',
              category: GarmentCategory.bottom,
              memberId: 'member-2',
            ),
            makeGarment(id: 'shoe-1', category: GarmentCategory.shoe),
          ],
        ),
        requirements: defaultRequirements,
        memberId: 'member-1',
      );

      expect(result.accepted, isFalse);
      expect(result.reason, contains('member'));
    });

    test('rejects separated outfit with wrong structure', () {
      final result = engine.evaluate(
        candidate: OutfitCandidate(
          templateType: OotdTemplateType.separated,
          garments: <Garment>[
            makeGarment(id: 'top-1', category: GarmentCategory.top),
            makeGarment(id: 'top-2', category: GarmentCategory.top),
            makeGarment(id: 'shoe-1', category: GarmentCategory.shoe),
          ],
        ),
        requirements: defaultRequirements,
      );

      expect(result.accepted, isFalse);
      expect(result.reason, contains('structure'));
    });

    test('rejects dress outfit with top', () {
      final result = engine.evaluate(
        candidate: OutfitCandidate(
          templateType: OotdTemplateType.dress,
          garments: <Garment>[
            makeGarment(id: 'dress-1', category: GarmentCategory.dress),
            makeGarment(id: 'top-1', category: GarmentCategory.top),
            makeGarment(id: 'shoe-1', category: GarmentCategory.shoe),
          ],
        ),
        requirements: defaultRequirements,
      );

      expect(result.accepted, isFalse);
      expect(result.reason, contains('structure'));
    });

    test('rejects outfit without shoes', () {
      final result = engine.evaluate(
        candidate: OutfitCandidate(
          templateType: OotdTemplateType.separated,
          garments: <Garment>[
            makeGarment(id: 'top-1', category: GarmentCategory.top),
            makeGarment(id: 'bottom-1', category: GarmentCategory.bottom),
          ],
        ),
        requirements: defaultRequirements,
      );

      expect(result.accepted, isFalse);
      expect(result.reason, contains('shoes'));
    });

    test('rejects suede footwear in extreme rain', () {
      final requirements = DailyRequirements(
        targetWarmth: 5,
        targetBreathability: 5,
        rainProtectionNeed: 9,
        windProtectionNeed: 2,
        targetFormality: 5,
        preferLightLayers: false,
        preferRemovableLayer: false,
        avoidSuede: true,
        avoidOpenFootwear: false,
        preferComfortableFootwear: false,
        avoidRestrictiveFits: false,
      );

      final result = engine.evaluate(
        candidate: separatedCandidate(
          garments: <Garment>[
            makeGarment(id: 'top-1', category: GarmentCategory.top),
            makeGarment(id: 'bottom-1', category: GarmentCategory.bottom),
            makeGarment(
              id: 'shoe-1',
              category: GarmentCategory.shoe,
              fabric: 'Suede',
            ),
          ],
        ),
        requirements: requirements,
      );

      expect(result.accepted, isFalse);
      expect(result.reason, contains('rain'));
    });

    test('rejects extreme cold incompatibility', () {
      final requirements = DailyRequirements(
        targetWarmth: 9,
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

      final result = engine.evaluate(
        candidate: separatedCandidate(
          garments: <Garment>[
            makeGarment(
              id: 'top-1',
              category: GarmentCategory.top,
              fabric: 'Linen',
              fabricWeight: 'Light',
              sleeveLength: 'Sleeveless',
              name: 'Linen Tank',
            ),
            makeGarment(
              id: 'bottom-1',
              category: GarmentCategory.bottom,
              fabric: 'Linen',
              fabricWeight: 'Light',
              name: 'Linen Shorts',
            ),
            makeGarment(
              id: 'shoe-1',
              category: GarmentCategory.shoe,
              fabric: 'Canvas',
              fabricWeight: 'Light',
              name: 'Light Sandals',
            ),
          ],
        ),
        requirements: requirements,
      );

      expect(result.accepted, isFalse);
      expect(result.reason, contains('cold'));
    });

    test('rejects extreme heat incompatibility', () {
      final requirements = DailyRequirements(
        targetWarmth: 1,
        targetBreathability: 10,
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

      final result = engine.evaluate(
        candidate: separatedCandidate(
          garments: <Garment>[
            makeGarment(
              id: 'top-1',
              category: GarmentCategory.top,
              fabric: 'Wool',
              fabricWeight: 'Heavy',
              sleeveLength: 'Long Sleeve',
              name: 'Heavy Wool Sweater',
            ),
            makeGarment(
              id: 'bottom-1',
              category: GarmentCategory.bottom,
              fabric: 'Wool',
              fabricWeight: 'Heavy',
              name: 'Wool Trousers',
            ),
            makeGarment(
              id: 'shoe-1',
              category: GarmentCategory.shoe,
              fabric: 'Wool',
              fabricWeight: 'Heavy',
              name: 'Wool Boots',
            ),
          ],
        ),
        requirements: requirements,
      );

      expect(result.accepted, isFalse);
      expect(result.reason, contains('heat'));
    });

    test('allows outerwear in separated outfit', () {
      final result = engine.evaluate(
        candidate: separatedCandidate(
          garments: <Garment>[
            makeGarment(id: 'top-1', category: GarmentCategory.top),
            makeGarment(id: 'bottom-1', category: GarmentCategory.bottom),
            makeGarment(id: 'shoe-1', category: GarmentCategory.shoe),
            makeGarment(
              id: 'jacket-1',
              category: GarmentCategory.outerwear,
            ),
          ],
        ),
        requirements: defaultRequirements,
      );

      expect(result.accepted, isTrue);
    });

    test('allows accessory in dress outfit', () {
      final result = engine.evaluate(
        candidate: dressCandidate(
          garments: <Garment>[
            makeGarment(id: 'dress-1', category: GarmentCategory.dress),
            makeGarment(id: 'shoe-1', category: GarmentCategory.shoe),
            makeGarment(
              id: 'bag-1',
              category: GarmentCategory.bag,
            ),
          ],
        ),
        requirements: defaultRequirements,
      );

      expect(result.accepted, isTrue);
    });
  });

  group('HardRuleResult', () {
    test('accepted result has accepted true and null reason', () {
      const result = HardRuleResult.accepted();
      expect(result.accepted, isTrue);
      expect(result.reason, isNull);
    });

    test('rejected result has accepted false and a reason', () {
      const result = HardRuleResult.rejected('test reason');
      expect(result.accepted, isFalse);
      expect(result.reason, 'test reason');
    });
  });
}
