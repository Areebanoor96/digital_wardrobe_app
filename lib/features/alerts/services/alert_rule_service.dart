import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/data/models/growth_measurement.dart';
import 'package:digital_wardrobe_app/features/profile/Family/services/growth_intelligence_service.dart';

class AlertRuleService {
  const AlertRuleService({
    this.growthIntelligenceService = const GrowthIntelligenceService(),
    this.now = _defaultNow,
  });

  final GrowthIntelligenceService growthIntelligenceService;
  final DateTime Function() now;

  List<Map<String, dynamic>> buildGarmentAlerts({
    required Garment garment,
    required String userId,
    required String memberId,
    required Set<String> existingKeys,
    required bool unusedAlertsEnabled,
    required bool laundryAlertsEnabled,
  }) {
    final List<Map<String, dynamic>> alerts = <Map<String, dynamic>>[];

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
      if (shouldHaveUnusedAlert(garment)) {
        alerts.add(<String, dynamic>{
          'user_id': userId,
          'member_id': memberId,
          'type': 'unused',
          'garment_id': garment.id,
          'target_type': 'garment',
          'target_id': garment.id,
          'action_payload': <String, dynamic>{'route': '/garments/${garment.id}'},
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
      if (shouldHaveUnusedAlert(garment)) {
        final int daysSinceLastWorn = now()
            .difference(garment.lastWornDate!)
            .inDays;

        alerts.add(<String, dynamic>{
          'user_id': userId,
          'member_id': memberId,
          'type': 'unused',
          'garment_id': garment.id,
          'target_type': 'garment',
          'target_id': garment.id,
          'action_payload': <String, dynamic>{'route': '/garments/${garment.id}'},
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

    if (shouldHaveLaundryAlert(garment)) {
      alerts.add(<String, dynamic>{
        'user_id': userId,
        'member_id': memberId,
        'type': 'laundry',
        'garment_id': garment.id,
        'target_type': 'garment',
        'target_id': garment.id,
        'action_payload': <String, dynamic>{'route': '/garments/${garment.id}'},
        'title': 'Laundry needed',
        'body': '${garment.name} is marked as dirty. Time for a wash!',
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
    required bool isOotdEligible,
    required String snapshotId,
  }) {
    if (!enabled) {
      return null;
    }

    if (!isOotdEligible) {
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
      'target_type': 'ootd_recommendation',
      'target_id': snapshotId,
      'action_payload': <String, dynamic>{
        'route': '/ootd/recommendations/$snapshotId',
      },
      'title': 'Your outfit suggestion is ready',
      'body': 'Check your Outfit of the Day for a fresh wardrobe suggestion.',
      'is_read': false,
      'is_dismissed': false,
    };
  }

  bool shouldHaveOotdAlert({
    required bool enabled,
    required bool isOotdEligible,
  }) {
    return enabled && isOotdEligible;
  }

  Map<String, dynamic>? buildGrowthAlert({
    required FamilyMember member,
    required List<GrowthMeasurement> measurements,
    required String userId,
    required Set<String> existingKeys,
    required bool enabled,
    bool hasReminderForLatestCycle = false,
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

    final bool needsReminder = growthIntelligenceService
        .needsMeasurementReminder(
          member: member,
          measurements: measurements,
          now: now(),
        );

    if (needsReminder) {
      if (hasReminderForLatestCycle) {
        return null;
      }

      return <String, dynamic>{
        'user_id': userId,
        'member_id': member.id,
        'type': 'growth',
        'garment_id': null,
        'target_type': 'family_member',
        'target_id': member.id,
        'action_payload': <String, dynamic>{
          'route': '/family/${member.id}',
          'section': 'growth',
        },
        'title': 'Time for a growth check',
        'body':
            'Update ${member.name}\'s measurements to keep their wardrobe sizes current.',
        'is_read': false,
        'is_dismissed': false,
      };
    }

    final GrowthComparison? comparison = growthIntelligenceService.compare(
      measurements: measurements,
    );

    if (comparison == null || !comparison.hasGrowthChange) {
      return null;
    }

    final List<String> changes = <String>[];

    final double? heightChange = comparison.heightChangeCm;

    if (heightChange != null && heightChange > 0) {
      changes.add('grown ${heightChange.toStringAsFixed(1)} cm');
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
      'target_type': 'family_member',
      'target_id': member.id,
      'action_payload': <String, dynamic>{
        'route': '/family/${member.id}',
        'section': 'growth',
      },
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
      now: now(),
    )) {
      return true;
    }

    final GrowthComparison? comparison = growthIntelligenceService.compare(
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
    final DateTime today = _dateOnly(now());

    if (!_isInRelevantSeason(garment, today)) {
      return false;
    }

    if (garment.wearCount == 0) {
      final DateTime? referenceDate = garment.purchaseDate ?? garment.createdAt;

      if (referenceDate == null) {
        return false;
      }

      return !today.isBefore(_addCalendarMonths(referenceDate, 3));
    }

    if (garment.lastWornDate != null && garment.wearCount > 0) {
      return !today.isBefore(_addCalendarMonths(garment.lastWornDate!, 3));
    }

    return false;
  }

  bool shouldHaveLaundryAlert(Garment garment) {
    return garment.laundryStatus == LaundryStatus.dirty;
  }

  bool _isInRelevantSeason(Garment garment, DateTime today) {
    final Set<String> seasons = garment.seasons
        .map((String season) => season.trim().toLowerCase())
        .where((String season) => season.isNotEmpty)
        .toSet();

    if (seasons.isEmpty || seasons.contains('all')) {
      return true;
    }

    return seasons.contains(_localSeason(today));
  }

  String _localSeason(DateTime date) {
    return switch (date.month) {
      12 || 1 || 2 => 'winter',
      3 || 4 => 'spring',
      5 || 6 || 7 || 8 || 9 => 'summer',
      _ => 'autumn',
    };
  }

  DateTime _addCalendarMonths(DateTime date, int months) {
    final DateTime source = _dateOnly(date);
    final int targetMonthIndex = source.month - 1 + months;
    final int year = source.year + targetMonthIndex ~/ 12;
    final int month = targetMonthIndex % 12 + 1;
    final int lastDay = DateTime(year, month + 1, 0).day;

    return DateTime(year, month, source.day.clamp(1, lastDay).toInt());
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
}

DateTime _defaultNow() => DateTime.now();
