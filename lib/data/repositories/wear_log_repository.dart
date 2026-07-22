import 'package:digital_wardrobe_app/data/models/wear_log.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WearLogRepository {
  WearLogRepository(this._client);
  final SupabaseClient _client;

  Future<void> createWearLog(String garmentId, {String? outfitId}) async {
    await _client.from('wear_log').insert(<String, dynamic>{
      'user_id': _client.auth.currentUser!.id,
      'garment_id': garmentId,
      'worn_date': _dateOnly(DateTime.now()),
      'outfit_id': outfitId,
    });
  }

  Future<void> createWearLogsForOutfit({
    required String outfitId,
    required List<String> garmentIds,
  }) async {
    for (final String garmentId in garmentIds) {
      await createWearLog(garmentId, outfitId: outfitId);
    }
  }

  Future<List<WearLog>> fetchGarmentHistory(String garmentId) async {
    final List<dynamic> rows = await _client
        .from('wear_log')
        .select()
        .eq('garment_id', garmentId)
        .order('worn_date', ascending: false);
    return rows
        .map(
          (dynamic row) =>
              WearLog.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<List<WearLog>> fetchRecentActivity({int limit = 10}) async {
    final List<dynamic> rows = await _client
        .from('wear_log')
        .select()
        .order('worn_date', ascending: false)
        .limit(limit);
    return rows
        .map(
          (dynamic row) =>
              WearLog.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<List<WearLog>> fetchMonthActivity(DateTime month) {
    final DateTime start = DateTime(month.year, month.month);
    return _fetchDateRange(start, DateTime(month.year, month.month + 1));
  }

  Future<List<WearLog>> fetchDayHistory(DateTime day) {
    final DateTime start = DateTime(day.year, day.month, day.day);
    return _fetchDateRange(start, start.add(const Duration(days: 1)));
  }

  Future<List<WearLog>> _fetchDateRange(DateTime start, DateTime end) async {
    final List<dynamic> rows = await _client
        .from('wear_log')
        .select()
        .gte('worn_date', _dateOnly(start))
        .lt('worn_date', _dateOnly(end))
        .order('worn_date', ascending: false);
    return rows
        .map(
          (dynamic row) =>
              WearLog.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  String _dateOnly(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
