import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/wear_log.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WearLogRepository {
  WearLogRepository(this._client);

  final SupabaseClient _client;

  /// Normalizes the requested wear date to a date-only value.
  ///
  /// Defaults to [now]'s date when no date is supplied and rejects dates in
  /// the future so an entry cannot be recorded for an unreasonable day.
  static DateTime resolveWornDate(DateTime? wornDate, {DateTime? now}) {
    final DateTime reference = now ?? DateTime.now();
    final DateTime today = DateTime(
      reference.year,
      reference.month,
      reference.day,
    );

    final DateTime chosenDate = wornDate == null
        ? today
        : DateTime(wornDate.year, wornDate.month, wornDate.day);

    if (chosenDate.isAfter(today)) {
      throw ArgumentError.value(
        wornDate,
        'wornDate',
        'A wear date cannot be in the future.',
      );
    }

    return chosenDate;
  }

  /// Builds the row payload for one `wear_log` insert.
  ///
  /// Event and notes are optional, so a wear can be recorded quickly without
  /// either. The database trigger keeps `wear_count`/`last_worn_date` in sync.
  static Map<String, dynamic> buildWearLogRow({
    required String userId,
    required String memberId,
    required String garmentId,
    required DateTime wornDate,
    String? outfitId,
    String? eventName,
    String? notes,
    LaundryStatus? laundryStatusAfter,
    double? weatherTemp,
    String? weatherCondition,
  }) {
    final String? cleanEventName = eventName?.trim();
    final String? cleanNotes = notes?.trim();
    final String? cleanWeatherCondition = weatherCondition?.trim();

    return <String, dynamic>{
      'user_id': userId,
      'member_id': memberId,
      'garment_id': garmentId,
      'worn_date': _dateOnly(wornDate),
      'outfit_id': outfitId,
      'event_name': cleanEventName == null || cleanEventName.isEmpty
          ? null
          : cleanEventName,
      'notes': cleanNotes == null || cleanNotes.isEmpty ? null : cleanNotes,
      'laundry_status_after': laundryStatusAfter?.name,
      'weather_temp': weatherTemp,
      'weather_cond':
          cleanWeatherCondition == null || cleanWeatherCondition.isEmpty
          ? null
          : cleanWeatherCondition,
    };
  }

  Future<void> createWearLog({
    required String memberId,
    required String garmentId,
    DateTime? wornDate,
    String? eventName,
    String? notes,
    String? outfitId,
    LaundryStatus? laundryStatusAfter,
    double? weatherTemp,
    String? weatherCondition,
  }) async {
    final User? currentUser = _client.auth.currentUser;

    if (currentUser == null) {
      throw StateError('No authenticated user.');
    }

    final DateTime resolvedWornDate = resolveWornDate(wornDate);

    await _client
        .from('wear_log')
        .insert(
          buildWearLogRow(
            userId: currentUser.id,
            memberId: memberId,
            garmentId: garmentId,
            wornDate: resolvedWornDate,
            outfitId: outfitId,
            eventName: eventName,
            notes: notes,
            laundryStatusAfter: laundryStatusAfter,
            weatherTemp: weatherTemp,
            weatherCondition: weatherCondition,
          ),
        );
  }

  Future<void> createWearLogsForOutfit({
    required String memberId,
    required String outfitId,
    required List<String> garmentIds,
    DateTime? wornDate,
    String? eventName,
    String? notes,
    LaundryStatus? laundryStatusAfter,
    double? weatherTemp,
    String? weatherCondition,
  }) async {
    final User? currentUser = _client.auth.currentUser;

    if (currentUser == null) {
      throw StateError('No authenticated user.');
    }

    if (garmentIds.isEmpty) {
      return;
    }

    final DateTime resolvedWornDate = resolveWornDate(wornDate);

    final List<Map<String, dynamic>> rows = garmentIds
        .map(
          (String garmentId) => buildWearLogRow(
            userId: currentUser.id,
            memberId: memberId,
            garmentId: garmentId,
            wornDate: resolvedWornDate,
            outfitId: outfitId,
            eventName: eventName,
            notes: notes,
            laundryStatusAfter: laundryStatusAfter,
            weatherTemp: weatherTemp,
            weatherCondition: weatherCondition,
          ),
        )
        .toList();

    await _client.from('wear_log').insert(rows);
  }

  /// Removes a single wear record after verifying the authenticated user owns
  /// it (user + member + garment). The database delete trigger restores
  /// `wear_count` and `last_worn_date` on the garment.
  Future<void> deleteWearLog({
    required String memberId,
    required String garmentId,
    required String wearLogId,
  }) async {
    final String userId = _requireUserId();

    final Map<String, dynamic>? row = await _client
        .from('wear_log')
        .select('id')
        .eq('id', wearLogId)
        .eq('user_id', userId)
        .eq('member_id', memberId)
        .eq('garment_id', garmentId)
        .maybeSingle();

    if (row == null) {
      throw StateError('Wear record not found for this profile.');
    }

    await _client
        .from('wear_log')
        .delete()
        .eq('id', wearLogId)
        .eq('user_id', userId)
        .eq('member_id', memberId)
        .eq('garment_id', garmentId);
  }

  Future<List<WearLog>> fetchGarmentHistory({
    required String memberId,
    required String garmentId,
  }) async {
    final List<dynamic> rows = await _client
        .from('wear_log')
        .select()
        .eq('user_id', _requireUserId())
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
        .eq('user_id', _requireUserId())
        .eq('member_id', memberId)
        .order('worn_date', ascending: false)
        .limit(limit);

    return _mapWearLogs(rows);
  }

  Future<List<WearLog>> fetchRecommendationWearHistory({
    required String memberId,
    int days = 90,
  }) async {
    final DateTime start = DateTime.now().subtract(Duration(days: days));

    final List<dynamic> rows = await _client
        .from('wear_log')
        .select()
        .eq('user_id', _requireUserId())
        .eq('member_id', memberId)
        .gte('worn_date', _dateOnly(start))
        .order('worn_date', ascending: false);

    return _mapWearLogs(rows);
  }

  Future<List<WearLog>> fetchMonthActivity({
    required String memberId,
    required DateTime month,
  }) {
    final DateTime start = DateTime(month.year, month.month);
    final DateTime end = DateTime(month.year, month.month + 1);

    return _fetchDateRange(memberId: memberId, start: start, end: end);
  }

  Future<List<WearLog>> fetchDayHistory({
    required String memberId,
    required DateTime day,
  }) {
    final DateTime start = DateTime(day.year, day.month, day.day);
    final DateTime end = start.add(const Duration(days: 1));

    return _fetchDateRange(memberId: memberId, start: start, end: end);
  }

  Future<List<WearLog>> _fetchDateRange({
    required String memberId,
    required DateTime start,
    required DateTime end,
  }) async {
    final List<dynamic> rows = await _client
        .from('wear_log')
        .select()
        .eq('user_id', _requireUserId())
        .eq('member_id', memberId)
        .gte('worn_date', _dateOnly(start))
        .lt('worn_date', _dateOnly(end))
        .order('worn_date', ascending: false);

    return _mapWearLogs(rows);
  }

  String _requireUserId() {
    final User? currentUser = _client.auth.currentUser;

    if (currentUser == null) {
      throw StateError('No authenticated user.');
    }

    return currentUser.id;
  }

  List<WearLog> _mapWearLogs(List<dynamic> rows) {
    return rows
        .map(
          (dynamic row) =>
              WearLog.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  static String _dateOnly(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> wearOutfitAtomically({
    required String memberId,
    required String outfitId,
    DateTime? wornDate,
    String? eventName,
    String? notes,
    LaundryStatus? laundryStatusAfter,
  }) async {
    final User? currentUser = _client.auth.currentUser;

    if (currentUser == null) {
      throw StateError('No authenticated user.');
    }

    final DateTime resolvedWornDate = resolveWornDate(wornDate);

    await _client.rpc(
      'wear_outfit',
      params: <String, dynamic>{
        'p_outfit_id': outfitId,
        'p_member_id': memberId,
        'p_worn_date': _dateOnly(resolvedWornDate),
        'p_event_name': eventName,
        'p_notes': notes,
        'p_laundry_status_after': laundryStatusAfter?.name,
      },
    );
  }
}
