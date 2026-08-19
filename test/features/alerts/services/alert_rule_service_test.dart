import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/growth_measurement.dart';
import 'package:digital_wardrobe_app/features/alerts/services/alert_rule_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const AlertRuleService service = AlertRuleService();

  // ============================================================
  // GROWTH ALERTS
  // ============================================================

  group('AlertRuleService - Growth Alerts', () {
    test('does not create growth alert when preference is disabled', () {
      final FamilyMember child = _makeChild();

      final Map<String, dynamic>? alert = service.buildGrowthAlert(
        member: child,
        measurements: const <GrowthMeasurement>[],
        userId: 'user-1',
        existingKeys: <String>{},
        enabled: false,
      );

      expect(alert, isNull);
    });

    test('does not create growth alert for an adult', () {
      final FamilyMember adult = FamilyMember(
        id: 'adult-1',
        name: 'Adult',
        relationship: RelationshipType.self,
        birthDate: DateTime(2000, 1, 1),
      );

      final Map<String, dynamic>? alert = service.buildGrowthAlert(
        member: adult,
        measurements: const <GrowthMeasurement>[],
        userId: 'user-1',
        existingKeys: <String>{},
        enabled: true,
      );

      expect(alert, isNull);
    });

    test('does not create duplicate active growth alert', () {
      final FamilyMember child = _makeChild();

      final Map<String, dynamic>? alert = service.buildGrowthAlert(
        member: child,
        measurements: const <GrowthMeasurement>[],
        userId: 'user-1',
        existingKeys: <String>{'growth_null'},
        enabled: true,
      );

      expect(alert, isNull);
    });

    test('does not recreate reminder when one exists for the latest cycle', () {
      final FamilyMember child = _makeChild();

      final List<GrowthMeasurement> measurements = <GrowthMeasurement>[
        GrowthMeasurement(
          id: 'measurement-old',
          memberId: child.id,
          heightCm: 140,
          recordedAt: DateTime.now().subtract(const Duration(days: 90)),
        ),
      ];

      final Map<String, dynamic>? alert = service.buildGrowthAlert(
        member: child,
        measurements: measurements,
        userId: 'user-1',
        existingKeys: <String>{},
        enabled: true,
        hasReminderForLatestCycle: true,
      );

      expect(alert, isNull);
    });

    test('creates reminder when none exists for the latest cycle', () {
      final FamilyMember child = _makeChild();

      final List<GrowthMeasurement> measurements = <GrowthMeasurement>[
        GrowthMeasurement(
          id: 'measurement-old',
          memberId: child.id,
          heightCm: 140,
          recordedAt: DateTime.now().subtract(const Duration(days: 90)),
        ),
      ];

      final Map<String, dynamic>? alert = service.buildGrowthAlert(
        member: child,
        measurements: measurements,
        userId: 'user-1',
        existingKeys: <String>{},
        enabled: true,
        hasReminderForLatestCycle: false,
      );

      expect(alert, isNotNull);
      expect(alert!['title'], 'Time for a growth check');
    });

    test('does not recreate reminder when no measurements exist yet', () {
      final FamilyMember child = _makeChild();

      final Map<String, dynamic>? alert = service.buildGrowthAlert(
        member: child,
        measurements: const <GrowthMeasurement>[],
        userId: 'user-1',
        existingKeys: <String>{},
        enabled: true,
        hasReminderForLatestCycle: true,
      );

      expect(alert, isNull);
    });

    test('creates measurement reminder when child has no measurements', () {
      final FamilyMember child = _makeChild();

      final Map<String, dynamic>? alert = service.buildGrowthAlert(
        member: child,
        measurements: const <GrowthMeasurement>[],
        userId: 'user-1',
        existingKeys: <String>{},
        enabled: true,
      );

      expect(alert, isNotNull);
      expect(alert!['type'], 'growth');
      expect(alert['member_id'], child.id);
      expect(alert['title'], 'Time for a growth check');
      expect(alert['garment_id'], isNull);
    });

    test('creates growth detected alert when height increases', () {
      final FamilyMember child = _makeChild();

      final List<GrowthMeasurement> measurements = <GrowthMeasurement>[
        GrowthMeasurement(
          id: 'measurement-new',
          memberId: child.id,
          heightCm: 145,
          recordedAt: DateTime.now(),
        ),
        GrowthMeasurement(
          id: 'measurement-old',
          memberId: child.id,
          heightCm: 140,
          recordedAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
      ];

      final Map<String, dynamic>? alert = service.buildGrowthAlert(
        member: child,
        measurements: measurements,
        userId: 'user-1',
        existingKeys: <String>{},
        enabled: true,
      );

      expect(alert, isNotNull);
      expect(alert!['title'], 'Growth detected');
      expect(alert['body'], contains('5.0 cm'));
    });

    test('creates growth alert when clothing size changes', () {
      final FamilyMember child = _makeChild();

      final List<GrowthMeasurement> measurements = <GrowthMeasurement>[
        GrowthMeasurement(
          id: 'measurement-new',
          memberId: child.id,
          clothingSize: 'M',
          recordedAt: DateTime.now(),
        ),
        GrowthMeasurement(
          id: 'measurement-old',
          memberId: child.id,
          clothingSize: 'S',
          recordedAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
      ];

      final Map<String, dynamic>? alert = service.buildGrowthAlert(
        member: child,
        measurements: measurements,
        userId: 'user-1',
        existingKeys: <String>{},
        enabled: true,
      );

      expect(alert, isNotNull);
      expect(alert!['title'], 'Growth detected');
      expect(alert['body'], contains('changed clothing size'));
    });

    test('creates growth alert when shoe size changes', () {
      final FamilyMember child = _makeChild();

      final List<GrowthMeasurement> measurements = <GrowthMeasurement>[
        GrowthMeasurement(
          id: 'measurement-new',
          memberId: child.id,
          shoeSize: '35',
          recordedAt: DateTime.now(),
        ),
        GrowthMeasurement(
          id: 'measurement-old',
          memberId: child.id,
          shoeSize: '34',
          recordedAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
      ];

      final Map<String, dynamic>? alert = service.buildGrowthAlert(
        member: child,
        measurements: measurements,
        userId: 'user-1',
        existingKeys: <String>{},
        enabled: true,
      );

      expect(alert, isNotNull);
      expect(alert!['title'], 'Growth detected');
      expect(alert['body'], contains('changed shoe size'));
    });

    test('shouldHaveGrowthAlert returns false for adult', () {
      final FamilyMember adult = FamilyMember(
        id: 'adult-1',
        name: 'Adult',
        relationship: RelationshipType.self,
        birthDate: DateTime(2000, 1, 1),
      );

      final bool result = service.shouldHaveGrowthAlert(
        member: adult,
        measurements: const <GrowthMeasurement>[],
      );

      expect(result, isFalse);
    });

    test(
      'shouldHaveGrowthAlert returns true for child needing measurement',
      () {
        final FamilyMember child = _makeChild();

        final bool result = service.shouldHaveGrowthAlert(
          member: child,
          measurements: const <GrowthMeasurement>[],
        );

        expect(result, isTrue);
      },
    );
  });

  // ============================================================
  // LAUNDRY ALERTS
  // ============================================================

  group('AlertRuleService - Laundry Alerts', () {
    test('dirty garment needs laundry alert', () {
      final Garment garment = _makeGarment(laundryStatus: LaundryStatus.dirty);

      expect(service.shouldHaveLaundryAlert(garment), isTrue);
    });

    test('clean garment does not need laundry alert', () {
      final Garment garment = _makeGarment(laundryStatus: LaundryStatus.clean);

      expect(service.shouldHaveLaundryAlert(garment), isFalse);
    });

    test('washing garment does not need dirty laundry alert', () {
      final Garment garment = _makeGarment(
        laundryStatus: LaundryStatus.washing,
      );

      expect(service.shouldHaveLaundryAlert(garment), isFalse);
    });

    test('ironing garment does not need dirty laundry alert', () {
      final Garment garment = _makeGarment(
        laundryStatus: LaundryStatus.ironing,
      );

      expect(service.shouldHaveLaundryAlert(garment), isFalse);
    });

    test('buildGarmentAlerts creates laundry alert for dirty garment', () {
      final Garment garment = _makeGarment(laundryStatus: LaundryStatus.dirty);

      final List<Map<String, dynamic>> alerts = service.buildGarmentAlerts(
        garment: garment,
        userId: 'user-1',
        memberId: 'member-1',
        existingKeys: <String>{},
        unusedAlertsEnabled: false,
        laundryAlertsEnabled: true,
      );

      expect(alerts.length, 1);
      expect(alerts.first['type'], 'laundry');
      expect(alerts.first['garment_id'], garment.id);
      expect(alerts.first['title'], 'Laundry needed');
    });

    test('does not create laundry alert when preference is disabled', () {
      final Garment garment = _makeGarment(laundryStatus: LaundryStatus.dirty);

      final List<Map<String, dynamic>> alerts = service.buildGarmentAlerts(
        garment: garment,
        userId: 'user-1',
        memberId: 'member-1',
        existingKeys: <String>{},
        unusedAlertsEnabled: false,
        laundryAlertsEnabled: false,
      );

      expect(alerts, isEmpty);
    });

    test('does not create duplicate laundry alert', () {
      final Garment garment = _makeGarment(
        id: 'shirt-1',
        laundryStatus: LaundryStatus.dirty,
      );

      final List<Map<String, dynamic>> alerts = service.buildGarmentAlerts(
        garment: garment,
        userId: 'user-1',
        memberId: 'member-1',
        existingKeys: <String>{'laundry_shirt-1'},
        unusedAlertsEnabled: false,
        laundryAlertsEnabled: true,
      );

      expect(alerts, isEmpty);
    });
  });

  // ============================================================
  // UNUSED GARMENT ALERTS
  // ============================================================

  group('AlertRuleService - Unused Alerts', () {
    test('unworn garment purchased more than 7 days ago needs alert', () {
      final Garment garment = _makeGarment(
        wearCount: 0,
        purchaseDate: DateTime.now().subtract(const Duration(days: 8)),
      );

      expect(service.shouldHaveUnusedAlert(garment), isTrue);
    });

    test('recently purchased unworn garment does not need alert', () {
      final Garment garment = _makeGarment(
        wearCount: 0,
        purchaseDate: DateTime.now().subtract(const Duration(days: 3)),
      );

      expect(service.shouldHaveUnusedAlert(garment), isFalse);
    });

    test('unworn garment without purchase date does not need alert', () {
      final Garment garment = _makeGarment(wearCount: 0);

      expect(service.shouldHaveUnusedAlert(garment), isFalse);
    });

    test('garment not worn for more than 30 days needs alert', () {
      final Garment garment = _makeGarment(
        wearCount: 5,
        lastWornDate: DateTime.now().subtract(const Duration(days: 31)),
      );

      expect(service.shouldHaveUnusedAlert(garment), isTrue);
    });

    test('recently worn garment does not need unused alert', () {
      final Garment garment = _makeGarment(
        wearCount: 5,
        lastWornDate: DateTime.now().subtract(const Duration(days: 5)),
      );

      expect(service.shouldHaveUnusedAlert(garment), isFalse);
    });

    test('buildGarmentAlerts creates unused alert when condition is met', () {
      final Garment garment = _makeGarment(
        wearCount: 0,
        purchaseDate: DateTime.now().subtract(const Duration(days: 8)),
      );

      final List<Map<String, dynamic>> alerts = service.buildGarmentAlerts(
        garment: garment,
        userId: 'user-1',
        memberId: 'member-1',
        existingKeys: <String>{},
        unusedAlertsEnabled: true,
        laundryAlertsEnabled: false,
      );

      expect(alerts.length, 1);
      expect(alerts.first['type'], 'unused');
      expect(alerts.first['garment_id'], garment.id);
      expect(alerts.first['title'], 'Unworn garment');
    });

    test('does not create unused alert when preference is disabled', () {
      final Garment garment = _makeGarment(
        wearCount: 0,
        purchaseDate: DateTime.now().subtract(const Duration(days: 8)),
      );

      final List<Map<String, dynamic>> alerts = service.buildGarmentAlerts(
        garment: garment,
        userId: 'user-1',
        memberId: 'member-1',
        existingKeys: <String>{},
        unusedAlertsEnabled: false,
        laundryAlertsEnabled: false,
      );

      expect(alerts, isEmpty);
    });

    test('does not create duplicate unused alert', () {
      final Garment garment = _makeGarment(
        id: 'shirt-1',
        wearCount: 0,
        purchaseDate: DateTime.now().subtract(const Duration(days: 8)),
      );

      final List<Map<String, dynamic>> alerts = service.buildGarmentAlerts(
        garment: garment,
        userId: 'user-1',
        memberId: 'member-1',
        existingKeys: <String>{'unused_shirt-1'},
        unusedAlertsEnabled: true,
        laundryAlertsEnabled: false,
      );

      expect(alerts, isEmpty);
    });
  });

  // ============================================================
  // OOTD ALERTS
  // ============================================================

  group('AlertRuleService - OOTD Alerts', () {
    test('creates OOTD alert when enabled and none exists today', () {
      final Map<String, dynamic>? alert = service.buildOotdAlert(
        userId: 'user-1',
        memberId: 'member-1',
        enabled: true,
        hasOotdAlertToday: false,
        isOotdEligible: true,
      );

      expect(alert, isNotNull);
      expect(alert!['type'], 'ootd');
      expect(alert['member_id'], 'member-1');
      expect(alert['garment_id'], isNull);
      expect(alert['title'], 'Your outfit suggestion is ready');
    });

    test('does not create OOTD alert when preference is disabled', () {
      final Map<String, dynamic>? alert = service.buildOotdAlert(
        userId: 'user-1',
        memberId: 'member-1',
        enabled: false,
        hasOotdAlertToday: false,
        isOotdEligible: true,
      );

      expect(alert, isNull);
    });

    test('does not create second OOTD alert on same day', () {
      final Map<String, dynamic>? alert = service.buildOotdAlert(
        userId: 'user-1',
        memberId: 'member-1',
        enabled: true,
        hasOotdAlertToday: true,
        isOotdEligible: true,
      );

      expect(alert, isNull);
    });

    test('does not create OOTD alert when wardrobe is not eligible', () {
      final Map<String, dynamic>? alert = service.buildOotdAlert(
        userId: 'user-1',
        memberId: 'member-1',
        enabled: true,
        hasOotdAlertToday: false,
        isOotdEligible: false,
      );

      expect(alert, isNull);
    });

    test('shouldHaveOotdAlert returns true when enabled and eligible', () {
      expect(
        service.shouldHaveOotdAlert(enabled: true, isOotdEligible: true),
        isTrue,
      );
    });

    test('shouldHaveOotdAlert returns false when disabled', () {
      expect(
        service.shouldHaveOotdAlert(enabled: false, isOotdEligible: true),
        isFalse,
      );
    });

    test('shouldHaveOotdAlert returns false when wardrobe is not eligible', () {
      expect(
        service.shouldHaveOotdAlert(enabled: true, isOotdEligible: false),
        isFalse,
      );
    });
  });
}

// ============================================================
// TEST HELPERS
// ============================================================

FamilyMember _makeChild() {
  return FamilyMember(
    id: 'child-1',
    name: 'Ali',
    relationship: RelationshipType.child,
    birthDate: DateTime(2015, 1, 1),
  );
}

Garment _makeGarment({
  String id = 'garment-1',
  LaundryStatus laundryStatus = LaundryStatus.clean,
  int wearCount = 0,
  DateTime? purchaseDate,
  DateTime? lastWornDate,
}) {
  return Garment(
    id: id,
    name: 'Test Garment',
    category: GarmentCategory.top,
    photoPaths: const <String>[],
    photoUrls: const <String>[],
    laundryStatus: laundryStatus,
    wearCount: wearCount,
    purchaseDate: purchaseDate,
    lastWornDate: lastWornDate,
  );
}
