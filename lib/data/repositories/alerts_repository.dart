import 'package:digital_wardrobe_app/data/models/alert.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlertsRepository {
  AlertsRepository(this._client);

  final SupabaseClient _client;

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
      _addUnusedAlert(garment, userId, memberId, existingKeys, newAlerts);

      _addLaundryAlert(garment, userId, memberId, existingKeys, newAlerts);
    }

    if (newAlerts.isEmpty) return 0;
    await _client.from('alerts').insert(newAlerts);
    return newAlerts.length;
  }

  void _addUnusedAlert(
    Garment garment,
    String userId,
    String memberId,
    Set<String> existingKeys,
    List<Map<String, dynamic>> newAlerts,
  ) {
    final String key = 'unused_${garment.id}';
    if (existingKeys.contains(key)) return;

    if (garment.wearCount == 0) {
      final int daysSince = garment.purchaseDate != null
          ? DateTime.now().difference(garment.purchaseDate!).inDays
          : 0;
      if (daysSince >= 7) {
        newAlerts.add(<String, dynamic>{
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
        newAlerts.add(<String, dynamic>{
          'user_id': userId,
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

  void _addLaundryAlert(
    Garment garment,
    String userId,
    String memberId,
    Set<String> existingKeys,
    List<Map<String, dynamic>> newAlerts,
  ) {
    final String key = 'laundry_${garment.id}';
    if (existingKeys.contains(key)) return;

    if (garment.laundryStatus == LaundryStatus.dirty) {
      newAlerts.add(<String, dynamic>{
        'user_id': userId,
        'member_id': memberId,
        'type': 'laundry',
        'garment_id': garment.id,
        'title': 'Laundry needed',
        'body': '${garment.name} is marked as dirty. Time for a wash!',
        'is_read': false,
        'is_dismissed': false,
      });
    }
  }
}
