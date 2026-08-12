import 'package:digital_wardrobe_app/data/models/alert.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/profile.dart';
import 'package:digital_wardrobe_app/features/alerts/services/alert_rule_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlertsRepository {
  AlertsRepository(
      this._client, {
        this.ruleService = const AlertRuleService(),
      });

  final SupabaseClient _client;
  final AlertRuleService ruleService;

  Future<List<Alert>> fetchAlerts({required String memberId}) async {
    final String userId = _client.auth.currentUser!.id;

    final List<dynamic> rows = await _client
        .from('alerts')
        .select()
        .eq('user_id', userId)
        .eq('member_id', memberId)
        .eq('is_dismissed', false)
        .order('created_at', ascending: false);

    return rows
        .map(
          (dynamic row) =>
          Alert.fromJson(Map<String, dynamic>.from(row as Map)),
    )
        .toList();
  }

  Future<void> markAsRead(String alertId) async {
    final String userId = _client.auth.currentUser!.id;

    await _client
        .from('alerts')
        .update(<String, bool>{'is_read': true})
        .eq('id', alertId)
        .eq('user_id', userId);
  }

  Future<void> dismissAlert(String alertId) async {
    final String userId = _client.auth.currentUser!.id;

    await _client
        .from('alerts')
        .update(<String, bool>{'is_dismissed': true})
        .eq('id', alertId)
        .eq('user_id', userId);
  }

  Future<int> generateAndInsertAlerts({
    required String memberId,
  }) async {
    final String userId = _client.auth.currentUser!.id;

    // Used for the once-per-day OOTD rule.
    final DateTime now = DateTime.now();
    final DateTime startOfToday = DateTime(
      now.year,
      now.month,
      now.day,
    );

    // Fetch the user's alert preferences.
    final Map<String, dynamic> profileRow = Map<String, dynamic>.from(
      await _client
          .from('profiles')
          .select(
        'id, '
            'unused_alerts_enabled, '
            'laundry_alerts_enabled, '
            'ootd_alerts_enabled',
      )
          .eq('id', userId)
          .single()
      as Map,
    );

    final Profile profile = Profile.fromJson(profileRow);

    // Active alerts are used to prevent duplicate garment alerts.
    final List<dynamic> existingRows = await _client
        .from('alerts')
        .select('type, garment_id')
        .eq('user_id', userId)
        .eq('member_id', memberId)
        .eq('is_dismissed', false);

    final Set<String> existingKeys = existingRows.map((dynamic row) {
      final Map<String, dynamic> value =
      Map<String, dynamic>.from(row as Map);

      return '${value['type']}_${value['garment_id']}';
    }).toSet();

    // OOTD has a separate once-per-day duplicate rule.
    // Dismissed OOTD alerts still count for the current day.
    final List<dynamic> todaysOotdRows = await _client
        .from('alerts')
        .select('id')
        .eq('user_id', userId)
        .eq('member_id', memberId)
        .eq('type', 'ootd')
        .gte(
      'created_at',
      startOfToday.toUtc().toIso8601String(),
    )
        .limit(1);

    final bool hasOotdAlertToday = todaysOotdRows.isNotEmpty;

    // Fetch all active garments for the selected wardrobe profile.
    final List<dynamic> garmentRows = await _client
        .from('garments')
        .select()
        .eq('user_id', userId)
        .eq('member_id', memberId)
        .eq('is_archived', false);

    final List<Garment> garments = garmentRows
        .map(
          (dynamic row) =>
          Garment.fromJson(Map<String, dynamic>.from(row as Map)),
    )
        .toList();

    // Remove alerts whose underlying condition no longer exists.
    await _resolveGarmentAlerts(
      userId: userId,
      memberId: memberId,
      garments: garments,
    );

    final List<Map<String, dynamic>> newAlerts =
    <Map<String, dynamic>>[];

    // Generate garment-specific alerts.
    for (final Garment garment in garments) {
      newAlerts.addAll(
        ruleService.buildGarmentAlerts(
          garment: garment,
          userId: userId,
          memberId: memberId,
          existingKeys: existingKeys,
          unusedAlertsEnabled: profile.unusedAlertsEnabled,
          laundryAlertsEnabled: profile.laundryAlertsEnabled,
        ),
      );
    }

    // Generate today's OOTD alert if allowed.
    final Map<String, dynamic>? ootdAlert =
    ruleService.buildOotdAlert(
      userId: userId,
      memberId: memberId,
      enabled: profile.ootdAlertsEnabled,
      hasOotdAlertToday: hasOotdAlertToday,
    );

    if (ootdAlert != null) {
      newAlerts.add(ootdAlert);
    }

    if (newAlerts.isEmpty) {
      return 0;
    }

    await _client.from('alerts').insert(newAlerts);

    return newAlerts.length;
  }

  Future<void> _resolveGarmentAlerts({
    required String userId,
    required String memberId,
    required List<Garment> garments,
  }) async {
    for (final Garment garment in garments) {
      // Resolve laundry alerts when the garment no longer needs laundry.
      if (!ruleService.shouldHaveLaundryAlert(garment)) {
        await _client
            .from('alerts')
            .update(<String, bool>{
          'is_dismissed': true,
        })
            .eq('user_id', userId)
            .eq('member_id', memberId)
            .eq('garment_id', garment.id)
            .eq('type', 'laundry')
            .eq('is_dismissed', false);
      }

      // Resolve unused alerts when the garment is no longer considered unused.
      if (!ruleService.shouldHaveUnusedAlert(garment)) {
        await _client
            .from('alerts')
            .update(<String, bool>{
          'is_dismissed': true,
        })
            .eq('user_id', userId)
            .eq('member_id', memberId)
            .eq('garment_id', garment.id)
            .eq('type', 'unused')
            .eq('is_dismissed', false);
      }
    }
  }
}