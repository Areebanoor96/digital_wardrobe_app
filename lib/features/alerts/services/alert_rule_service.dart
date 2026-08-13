import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/data/models/growth_measurement.dart';
import 'package:digital_wardrobe_app/features/profile/Family/services/growth_intelligence_service.dart';

class AlertRuleService {
  const AlertRuleService({
    this.growthIntelligenceService =
    const GrowthIntelligenceService(),
  });

  final GrowthIntelligenceService growthIntelligenceService;

  List<Map<String, dynamic>> buildGarmentAlerts({
    required Garment garment,
    required String userId,
    required String memberId,
    required Set<String> existingKeys,
    required bool unusedAlertsEnabled,
    required bool laundryAlertsEnabled,
  }) {
    final List<Map<String, dynamic>> alerts =
    <Map<String, dynamic>>[];

    if (unusedAlertsEnabled) {
      _addUnusedAlert(
        garment: garment,
        userId: userId,
        memberId: memberId,
        existingKeys: existingKeys,
        alerts: alerts,
      );
    }

    if (laundryAlertsEnabled) {
      _addLaundryAlert(
        garment: garment,
        userId: userId,
        memberId: memberId,
        existingKeys: existingKeys,
        alerts: alerts,
      );
    }

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

    if (shouldHaveLaundryAlert(garment)){
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
    required bool enabled,
    required bool hasOotdAlertToday,
  }) {
    if (!enabled) {
      return null;
    }

    if (hasOotdAlertToday) {
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

  Map<String, dynamic>? buildGrowthAlert({
    required FamilyMember member,
    required List<GrowthMeasurement> measurements,
    required String userId,
    required Set<String> existingKeys,
    required bool enabled,
  }) {
    if (!enabled) {
      return null;
    }

    if (!growthIntelligenceService.isEligibleForGrowthTracking(member)) {
      return null;
    }

    const String key = 'growth_null';

    if (existingKeys.contains(key)) {
      return null;
    }

    final bool needsReminder =
    growthIntelligenceService.needsMeasurementReminder(
      member: member,
      measurements: measurements,
    );

    if (needsReminder) {
      return <String, dynamic>{
        'user_id': userId,
        'member_id': member.id,
        'type': 'growth',
        'garment_id': null,
        'title': 'Time for a growth check',
        'body':
        'Update ${member.name}\'s measurements to keep their wardrobe sizes current.',
        'is_read': false,
        'is_dismissed': false,
      };
    }

    final GrowthComparison? comparison =
    growthIntelligenceService.compare(
      measurements: measurements,
    );

    if (comparison == null || !comparison.hasGrowthChange) {
      return null;
    }

    final List<String> changes = <String>[];

    final double? heightChange = comparison.heightChangeCm;

    if (heightChange != null && heightChange > 0) {
      changes.add(
        'grown ${heightChange.toStringAsFixed(1)} cm',
      );
    }

    if (comparison.clothingSizeChanged) {
      changes.add('changed clothing size');
    }

    if (comparison.shoeSizeChanged) {
      changes.add('changed shoe size');
    }

    if (changes.isEmpty) {
      return null;
    }

    return <String, dynamic>{
      'user_id': userId,
      'member_id': member.id,
      'type': 'growth',
      'garment_id': null,
      'title': 'Growth detected',
      'body':
      '${member.name} has ${_joinChanges(changes)}. '
          'Review their wardrobe to see what still fits.',
      'is_read': false,
      'is_dismissed': false,
    };
  }
  bool shouldHaveGrowthAlert({
    required FamilyMember member,
    required List<GrowthMeasurement> measurements,
  }) {
    if (!growthIntelligenceService.isEligibleForGrowthTracking(member)) {
      return false;
    }

    if (growthIntelligenceService.needsMeasurementReminder(
      member: member,
      measurements: measurements,
    )) {
      return true;
    }

    final GrowthComparison? comparison =
    growthIntelligenceService.compare(
      measurements: measurements,
    );

    return comparison?.hasGrowthChange ?? false;
  }
  String _joinChanges(List<String> changes) {
    if (changes.length == 1) {
      return changes.first;
    }

    if (changes.length == 2) {
      return '${changes[0]} and ${changes[1]}';
    }

    return '${changes.sublist(0, changes.length - 1).join(', ')}, '
        'and ${changes.last}';
  }
  bool shouldHaveUnusedAlert(Garment garment) {
    final DateTime now = DateTime.now();

    if (garment.wearCount == 0) {
      if (garment.purchaseDate == null) {
        return false;
      }

      final int daysSincePurchase =
          now.difference(garment.purchaseDate!).inDays;

      return daysSincePurchase >= 7;
    }

    if (garment.lastWornDate != null && garment.wearCount > 0) {
      final int daysSinceLastWorn =
          now.difference(garment.lastWornDate!).inDays;

      return daysSinceLastWorn >= 30;
    }

    return false;
  }

  bool shouldHaveLaundryAlert(Garment garment) {
    return garment.laundryStatus == LaundryStatus.dirty;
  }
}