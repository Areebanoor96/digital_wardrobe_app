import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/wear_log.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WearLogRepository {
  WearLogRepository(this._client);

  final SupabaseClient _client;

  Future<void> createWearLog({
    required String memberId,
    required String garmentId,
    required String eventName,
    required LaundryStatus laundryStatusAfter,
    String? notes,
    String? outfitId,
  }) async {
    final User? currentUser = _client.auth.currentUser;

    if (currentUser == null) {
      throw StateError('No authenticated user.');
    }

    final String cleanEventName = eventName.trim();
    final String? cleanNotes = notes?.trim();

    if (cleanEventName.isEmpty) {
      throw ArgumentError('A wear event is required.');
    }

    await _client.from('wear_log').insert(<String, dynamic>{
      'user_id': currentUser.id,
      'member_id': memberId,
      'garment_id': garmentId,
      'worn_date': _dateOnly(DateTime.now()),
      'outfit_id': outfitId,
      'event_name': cleanEventName,
      'notes': cleanNotes == null || cleanNotes.isEmpty ? null : cleanNotes,
      'laundry_status_after': laundryStatusAfter.name,
    });

    await _client
        .from('garments')
        .update(<String, dynamic>{
      'laundry_status': laundryStatusAfter.name,
    })
        .eq('id', garmentId)
        .eq('member_id', memberId)
        .eq('user_id', currentUser.id);
  }

  Future<void> createWearLogsForOutfit({
    required String memberId,
    required String outfitId,
    required List<String> garmentIds,
    String? eventName,
    String? notes,
    LaundryStatus? laundryStatusAfter,
  }) async {
    final User? currentUser = _client.auth.currentUser;

    if (currentUser == null) {
      throw StateError('No authenticated user.');
    }

    if (garmentIds.isEmpty) {
      return;
    }

    final String wornDate = _dateOnly(DateTime.now());
    final String? cleanEventName = eventName?.trim();
    final String? cleanNotes = notes?.trim();

    final List<Map<String, dynamic>> rows = garmentIds
        .map(
          (String garmentId) => <String, dynamic>{
        'user_id': currentUser.id,
        'member_id': memberId,
        'garment_id': garmentId,
        'outfit_id': outfitId,
        'worn_date': wornDate,
        'event_name':
        cleanEventName == null || cleanEventName.isEmpty
            ? null
            : cleanEventName,
        'notes': cleanNotes == null || cleanNotes.isEmpty
            ? null
            : cleanNotes,
        'laundry_status_after': laundryStatusAfter?.name,
      },
    )
        .toList();

    await _client.from('wear_log').insert(rows);

    if (laundryStatusAfter != null) {
      await _client
          .from('garments')
          .update(<String, dynamic>{
        'laundry_status': laundryStatusAfter.name,
      })
          .inFilter('id', garmentIds)
          .eq('member_id', memberId)
          .eq('user_id', currentUser.id);
    }
  }

  Future<List<WearLog>> fetchGarmentHistory({
    required String memberId,
    required String garmentId,
  }) async {
    final List<dynamic> rows = await _client
        .from('wear_log')
        .select()
        .eq('member_id', memberId)
        .eq('garment_id', garmentId)
        .order('worn_date', ascending: false);

    return _mapWearLogs(rows);
  }

  Future<List<WearLog>> fetchRecentActivity({
    required String memberId,
    int limit = 10,
  }) async {
    final List<dynamic> rows = await _client
        .from('wear_log')
        .select()
        .eq('member_id', memberId)
        .order('worn_date', ascending: false)
        .limit(limit);

    return _mapWearLogs(rows);
  }

  Future<List<WearLog>> fetchMonthActivity({
    required String memberId,
    required DateTime month,
  }) {
    final DateTime start = DateTime(month.year, month.month);
    final DateTime end = DateTime(month.year, month.month + 1);

    return _fetchDateRange(
      memberId: memberId,
      start: start,
      end: end,
    );
  }

  Future<List<WearLog>> fetchDayHistory({
    required String memberId,
    required DateTime day,
  }) {
    final DateTime start = DateTime(day.year, day.month, day.day);
    final DateTime end = start.add(const Duration(days: 1));

    return _fetchDateRange(
      memberId: memberId,
      start: start,
      end: end,
    );
  }

  Future<List<WearLog>> _fetchDateRange({
    required String memberId,
    required DateTime start,
    required DateTime end,
  }) async {
    final List<dynamic> rows = await _client
        .from('wear_log')
        .select()
        .eq('member_id', memberId)
        .gte('worn_date', _dateOnly(start))
        .lt('worn_date', _dateOnly(end))
        .order('worn_date', ascending: false);

    return _mapWearLogs(rows);
  }

  List<WearLog> _mapWearLogs(List<dynamic> rows) {
    return rows
        .map(
          (dynamic row) =>
          WearLog.fromJson(Map<String, dynamic>.from(row as Map)),
    )
        .toList();
  }

  String _dateOnly(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}