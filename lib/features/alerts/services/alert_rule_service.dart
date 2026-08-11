import 'package:digital_wardrobe_app/data/models/garment.dart';

class AlertRuleService {
  const AlertRuleService();

  List<Map<String, dynamic>> buildGarmentAlerts({
    required Garment garment,
    required String userId,
    required String memberId,
    required Set<String> existingKeys,
  }) {
    final List<Map<String, dynamic>> alerts =
    <Map<String, dynamic>>[];

    _addUnusedAlert(
      garment: garment,
      userId: userId,
      memberId: memberId,
      existingKeys: existingKeys,
      alerts: alerts,
    );

    _addLaundryAlert(
      garment: garment,
      userId: userId,
      memberId: memberId,
      existingKeys: existingKeys,
      alerts: alerts,
    );

    return alerts;
  }

  void _addUnusedAlert({
    required Garment garment,
    required String userId,
    required String memberId,
    required Set<String> existingKeys,
    required List<Map<String, dynamic>> alerts,
  }) {
    final String key = 'unused_${garment.id}';

    if (existingKeys.contains(key)) {
      return;
    }

    if (garment.wearCount == 0) {
      final int daysSincePurchase = garment.purchaseDate == null
          ? 0
          : DateTime.now()
          .difference(garment.purchaseDate!)
          .inDays;

      if (daysSincePurchase >= 7) {
        alerts.add(<String, dynamic>{
          'user_id': userId,
          'member_id': memberId,
          'type': 'unused',
          'garment_id': garment.id,
          'title': 'Unworn garment',
          'body':
          '${garment.name} has not been worn yet. Try styling it into an outfit!',
          'is_read': false,
          'is_dismissed': false,
        });

        return;
      }
    }

    if (garment.lastWornDate != null && garment.wearCount > 0) {
      final int daysSinceLastWorn = DateTime.now()
          .difference(garment.lastWornDate!)
          .inDays;

      if (daysSinceLastWorn >= 30) {
        alerts.add(<String, dynamic>{
          'user_id': userId,
          'member_id': memberId,
          'type': 'unused',
          'garment_id': garment.id,
          'title': 'Not worn recently',
          'body':
          '${garment.name} hasn\'t been worn in $daysSinceLastWorn days. Time to rotate it back in!',
          'is_read': false,
          'is_dismissed': false,
        });
      }
    }
  }

  void _addLaundryAlert({
    required Garment garment,
    required String userId,
    required String memberId,
    required Set<String> existingKeys,
    required List<Map<String, dynamic>> alerts,
  }) {
    final String key = 'laundry_${garment.id}';

    if (existingKeys.contains(key)) {
      return;
    }

    if (garment.laundryStatus == LaundryStatus.dirty) {
      alerts.add(<String, dynamic>{
        'user_id': userId,
        'member_id': memberId,
        'type': 'laundry',
        'garment_id': garment.id,
        'title': 'Laundry needed',
        'body':
        '${garment.name} is marked as dirty. Time for a wash!',
        'is_read': false,
        'is_dismissed': false,
      });
    }
  }
  Map<String, dynamic>? buildOotdAlert({
    required String userId,
    required String memberId,
    required Set<String> existingKeys,
  }) {
    const String key = 'ootd_null';

    if (existingKeys.contains(key)) {
      return null;
    }

    return <String, dynamic>{
      'user_id': userId,
      'member_id': memberId,
      'type': 'ootd',
      'garment_id': null,
      'title': 'Your outfit suggestion is ready',
      'body':
      'Check your Outfit of the Day for a fresh wardrobe suggestion.',
      'is_read': false,
      'is_dismissed': false,
    };
  }
}