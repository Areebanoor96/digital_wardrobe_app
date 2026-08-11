import 'package:digital_wardrobe_app/data/models/alert.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:digital_wardrobe_app/features/alerts/services/alert_rule_service.dart';


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

  Future<int> generateAndInsertAlerts({required String memberId}) async {
    final String userId = _client.auth.currentUser!.id;

    final List<dynamic> existingRows = await _client
        .from('alerts')
        .select('type, garment_id')
        .eq('user_id', userId)
        .eq('member_id', memberId)
        .eq('is_dismissed', false);

    final Set<String> existingKeys = existingRows.map((dynamic row) {
      final Map<String, dynamic> r = Map<String, dynamic>.from(row as Map);
      return '${r['type']}_${r['garment_id']}';
    }).toSet();

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

    final List<Map<String, dynamic>> newAlerts = <Map<String, dynamic>>[];
    for (final Garment garment in garments) {
      newAlerts.addAll(
        ruleService.buildGarmentAlerts(
          garment: garment,
          userId: userId,
          memberId: memberId,
          existingKeys: existingKeys,
        ),
      );
    }
    final Map<String, dynamic>? ootdAlert =
    ruleService.buildOotdAlert(
      userId: userId,
      memberId: memberId,
      existingKeys: existingKeys,
    );

    if (ootdAlert != null) {
      newAlerts.add(ootdAlert);
    }


    if (newAlerts.isEmpty) return 0;
    await _client.from('alerts').insert(newAlerts);
    return newAlerts.length;
  }
}
