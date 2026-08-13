import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/data/models/growth_measurement.dart';
import 'package:digital_wardrobe_app/features/profile/Family/services/growth_intelligence_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const GrowthIntelligenceService service = GrowthIntelligenceService();

  group('GrowthIntelligenceService', () {
    test('non-child member is not eligible for growth tracking', () {
      final FamilyMember member = FamilyMember(
        id: 'member-1',
        name: 'Adult',
        relationship: RelationshipType.self,
        birthDate: DateTime(2000, 1, 1),
      );

      expect(
        service.isEligibleForGrowthTracking(member),
        isFalse,
      );
    });

    test('child under 18 is eligible for growth tracking', () {
      final FamilyMember member = FamilyMember(
        id: 'member-1',
        name: 'Child',
        relationship: RelationshipType.child,
        birthDate: DateTime.now().subtract(
          const Duration(days: 365 * 10),
        ),
      );

      expect(
        service.isEligibleForGrowthTracking(member),
        isTrue,
      );
    });

    test('child without birth date is not eligible', () {
      const FamilyMember member = FamilyMember(
        id: 'member-1',
        name: 'Child',
        relationship: RelationshipType.child,
      );

      expect(
        service.isEligibleForGrowthTracking(member),
        isFalse,
      );
    });

    test('returns null comparison with fewer than two measurements', () {
      expect(
        service.compare(measurements: const <GrowthMeasurement>[]),
        isNull,
      );
    });

    test('detects height increase between measurements', () {
      final List<GrowthMeasurement> measurements = <GrowthMeasurement>[
        GrowthMeasurement(
          id: 'new',
          memberId: 'member-1',
          heightCm: 145,
          recordedAt: DateTime(2026, 8, 1),
        ),
        GrowthMeasurement(
          id: 'old',
          memberId: 'member-1',
          heightCm: 140,
          recordedAt: DateTime(2026, 5, 1),
        ),
      ];

      final GrowthComparison? result =
      service.compare(measurements: measurements);

      expect(result, isNotNull);
      expect(result!.heightChangeCm, 5);
      expect(result.hasGrowthChange, isTrue);
    });

    test('detects clothing size change', () {
      final List<GrowthMeasurement> measurements = <GrowthMeasurement>[
        GrowthMeasurement(
          id: 'new',
          memberId: 'member-1',
          clothingSize: 'M',
          recordedAt: DateTime(2026, 8, 1),
        ),
        GrowthMeasurement(
          id: 'old',
          memberId: 'member-1',
          clothingSize: 'S',
          recordedAt: DateTime(2026, 5, 1),
        ),
      ];

      final GrowthComparison? result =
      service.compare(measurements: measurements);

      expect(result, isNotNull);
      expect(result!.clothingSizeChanged, isTrue);
      expect(result.hasGrowthChange, isTrue);
    });

    test('detects shoe size change', () {
      final List<GrowthMeasurement> measurements = <GrowthMeasurement>[
        GrowthMeasurement(
          id: 'new',
          memberId: 'member-1',
          shoeSize: '35',
          recordedAt: DateTime(2026, 8, 1),
        ),
        GrowthMeasurement(
          id: 'old',
          memberId: 'member-1',
          shoeSize: '34',
          recordedAt: DateTime(2026, 5, 1),
        ),
      ];

      final GrowthComparison? result =
      service.compare(measurements: measurements);

      expect(result, isNotNull);
      expect(result!.shoeSizeChanged, isTrue);
    });

    test('measurement reminder is needed after 90 days', () {
      final FamilyMember child = FamilyMember(
        id: 'member-1',
        name: 'Child',
        relationship: RelationshipType.child,
        birthDate: DateTime(2015, 1, 1),
      );

      final DateTime now = DateTime(2026, 8, 13);

      final List<GrowthMeasurement> measurements = <GrowthMeasurement>[
        GrowthMeasurement(
          id: 'measurement-1',
          memberId: child.id,
          heightCm: 140,
          recordedAt: now.subtract(const Duration(days: 90)),
        ),
      ];

      expect(
        service.needsMeasurementReminder(
          member: child,
          measurements: measurements,
          now: now,
        ),
        isTrue,
      );
    });

    test('recent measurement does not need reminder', () {
      final FamilyMember child = FamilyMember(
        id: 'member-1',
        name: 'Child',
        relationship: RelationshipType.child,
        birthDate: DateTime(2015, 1, 1),
      );

      final DateTime now = DateTime(2026, 8, 13);

      final List<GrowthMeasurement> measurements = <GrowthMeasurement>[
        GrowthMeasurement(
          id: 'measurement-1',
          memberId: child.id,
          heightCm: 140,
          recordedAt: now.subtract(const Duration(days: 30)),
        ),
      ];

      expect(
        service.needsMeasurementReminder(
          member: child,
          measurements: measurements,
          now: now,
        ),
        isFalse,
      );
    });
  });
}