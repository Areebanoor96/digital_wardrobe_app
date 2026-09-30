import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/growth_measurement.dart';
import 'package:digital_wardrobe_app/features/profile/Family/services/size_growth_prediction_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const SizeGrowthPredictionService service = SizeGrowthPredictionService();
  final DateTime now = DateTime(2026, 1, 15);

  FamilyMember child({
    String? currentSize,
    String? shoeSize,
    DateTime? birthDate,
  }) => FamilyMember(
    id: 'child-1',
    name: 'Ali',
    relationship: RelationshipType.child,
    birthDate: birthDate ?? DateTime(2025, 1, 1),
    currentSize: currentSize,
    shoeSize: shoeSize,
  );

  Garment garment({
    String id = 'g-1',
    String? size,
    GarmentCategory category = GarmentCategory.top,
  }) => Garment(
    id: id,
    name: 'Hoodie',
    category: category,
    size: size,
    photoPaths: const <String>[],
    photoUrls: const <String>[],
  );

  group('SizeGrowthPredictionService', () {
    test('predicts within the lead time for a toddler', () {
      final SizeGrowthPrediction? prediction = service.predict(
        member: child(currentSize: '0-1M'),
        garment: garment(size: '1-3M'),
        now: now,
      );

      expect(prediction, isNotNull);
      expect(prediction!.garmentId, 'g-1');
      expect(prediction.garmentSize, '1-3M');
      expect(prediction.estimatedOutgrowthMonth, 'April');
    });

    test('returns null for an adult', () {
      final FamilyMember adult = FamilyMember(
        id: 'adult-1',
        name: 'Adult',
        relationship: RelationshipType.self,
        birthDate: DateTime(2000, 1, 1),
        currentSize: 'M',
      );

      expect(
        service.predict(
          member: adult,
          garment: garment(size: 'L'),
          now: now,
        ),
        isNull,
      );
    });

    test('returns null for a child without a birth date', () {
      final FamilyMember member = FamilyMember(
        id: 'child-1',
        name: 'Ali',
        relationship: RelationshipType.child,
        currentSize: '0-1M',
      );

      expect(
        service.predict(
          member: member,
          garment: garment(size: '1-3M'),
          now: now,
        ),
        isNull,
      );
    });

    test('returns null for non-size garments', () {
      expect(
        service.predict(
          member: child(currentSize: '0-1M'),
          garment: garment(size: 'M', category: GarmentCategory.accessory),
          now: now,
        ),
        isNull,
      );
    });

    test('returns null when the garment size is unrecognized', () {
      expect(
        service.predict(
          member: child(currentSize: '0-1M'),
          garment: garment(size: 'One size'),
          now: now,
        ),
        isNull,
      );
    });

    test('returns null when the current size is unrecognized', () {
      expect(
        service.predict(
          member: child(currentSize: 'One size'),
          garment: garment(size: '1-3M'),
          now: now,
        ),
        isNull,
      );
    });

    test('returns null when the garment is already smaller than the child', () {
      final SizeGrowthPrediction? prediction = service.predict(
        member: child(currentSize: '6-9M'),
        garment: garment(size: '0-1M'),
        now: now,
      );

      expect(prediction, isNull);
    });

    test('returns null beyond the lead time', () {
      expect(
        service.predict(
          member: child(currentSize: '0-1M'),
          garment: garment(size: '6-9M'),
          now: now,
        ),
        isNull,
      );
    });

    test('uses the latest measurement over the member record', () {
      final List<GrowthMeasurement> measurements = <GrowthMeasurement>[
        GrowthMeasurement(
          id: 'older',
          memberId: 'child-1',
          clothingSize: '0-1M',
          recordedAt: DateTime(2025, 10, 1),
        ),
        GrowthMeasurement(
          id: 'latest',
          memberId: 'child-1',
          clothingSize: '3-6M',
          recordedAt: DateTime(2026, 1, 1),
        ),
      ];

      final SizeGrowthPrediction? prediction = service.predict(
        member: child(currentSize: '0-1M'),
        garment: garment(size: '6-9M'),
        measurements: measurements,
        now: now,
      );

      expect(prediction, isNotNull);
      expect(prediction!.garmentSize, '6-9M');
    });

    test('falls back to the member record when no measurements exist', () {
      final SizeGrowthPrediction? prediction = service.predict(
        member: child(currentSize: '0-1M'),
        garment: garment(size: '1-3M'),
        now: now,
      );

      expect(prediction, isNotNull);
    });

    test('uses a slower growth step for older children', () {
      // A three-year-old spends ~6 months per size step, which is beyond the
      // 3 month lead time even one step ahead.
      final FamilyMember older = child(
        birthDate: DateTime(2023, 1, 1),
        currentSize: '0-1M',
      );

      expect(
        service.predict(
          member: older,
          garment: garment(size: '1-3M'),
          now: now,
        ),
        isNull,
      );
    });

    test('predicts shoe growth from numeric sizes', () {
      final FamilyMember member = child(shoeSize: '21');

      final SizeGrowthPrediction? prediction = service.predict(
        member: member,
        garment: garment(size: '22', category: GarmentCategory.shoe),
        now: now,
      );

      expect(prediction, isNotNull);
      expect(prediction!.garmentSize, '22');
    });

    test('returns null for unrecognized shoe sizes', () {
      final FamilyMember member = child(shoeSize: '21');

      expect(
        service.predict(
          member: member,
          garment: garment(size: '5', category: GarmentCategory.shoe),
          now: now,
        ),
        isNull,
      );
    });

    test('caps the prediction at the last day of the month', () {
      final SizeGrowthPrediction? prediction = const SizeGrowthPredictionService()
          .predict(
            member: child(currentSize: '0-1M'),
            garment: garment(size: '1-3M'),
            now: DateTime(2026, 1, 31),
          );

      expect(prediction, isNotNull);
      expect(prediction!.estimatedOutgrowthDate, DateTime(2026, 4, 30));
    });
  });
}