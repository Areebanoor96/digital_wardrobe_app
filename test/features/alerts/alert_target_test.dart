import 'package:digital_wardrobe_app/data/models/alert.dart';
import 'package:digital_wardrobe_app/features/alerts/navigation/alert_target_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Alert target parsing', () {
    test('parses generic target fields and timestamps', () {
      final Alert alert = Alert.fromJson(<String, dynamic>{
        'id': 'alert-1',
        'user_id': 'user-1',
        'member_id': 'member-1',
        'type': 'unused',
        'garment_id': 'garment-1',
        'target_type': 'garment',
        'target_id': 'garment-1',
        'action_payload': <String, dynamic>{'route': '/garments/garment-1'},
        'title': 'Unworn garment',
        'body': 'Try this garment.',
        'is_read': true,
        'is_dismissed': false,
        'read_at': '2026-08-28T08:00:00Z',
        'dismissed_at': null,
        'created_at': '2026-08-28T07:00:00Z',
      });

      expect(alert.targetType, AlertTargetTypes.garment);
      expect(alert.targetId, 'garment-1');
      expect(alert.actionPayload['route'], '/garments/garment-1');
      expect(alert.readAt, DateTime.parse('2026-08-28T08:00:00Z'));
      expect(alert.dismissedAt, isNull);
    });
  });

  group('Alert target routes', () {
    test('routes garment targets to garment detail', () {
      expect(
        routeForAlert(_alert(targetType: 'garment', targetId: 'garment-1')),
        '/garments/garment-1',
      );
    });

    test('routes growth targets to family member detail', () {
      expect(
        routeForAlert(
          _alert(targetType: 'family_member', targetId: 'member-1'),
        ),
        '/family/member-1',
      );
    });

    test('routes OOTD targets to recommendation snapshot', () {
      expect(
        routeForAlert(
          _alert(
            type: AlertType.ootd,
            targetType: 'ootd_recommendation',
            targetId: 'snapshot-1',
          ),
        ),
        '/ootd/recommendations/snapshot-1',
      );
    });

    test('routes saved outfit targets to outfit detail', () {
      expect(
        routeForAlert(_alert(targetType: 'outfit', targetId: 'outfit-1')),
        '/outfits/outfit-1',
      );
    });

    test('falls back to legacy garment id for old alerts', () {
      expect(routeForAlert(_alert(garmentId: 'legacy-1')), '/garments/legacy-1');
    });

    test('returns null for missing or deleted target metadata', () {
      expect(routeForAlert(_alert()), isNull);
    });
  });
}

Alert _alert({
  AlertType type = AlertType.unused,
  String? garmentId,
  String? targetType,
  String? targetId,
}) {
  return Alert(
    id: 'alert-1',
    memberId: 'member-1',
    userId: 'user-1',
    type: type,
    garmentId: garmentId,
    targetType: targetType,
    targetId: targetId,
    title: 'Alert',
  );
}
