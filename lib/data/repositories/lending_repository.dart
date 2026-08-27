import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/lending_record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LendingRepository {
  LendingRepository(this._client);

  final SupabaseClient _client;

  Future<LendingRecord?> fetchActiveRecord({
    required String memberId,
    required String garmentId,
  }) async {
    await _verifyGarmentOwnership(memberId: memberId, garmentId: garmentId);

    final Map<String, dynamic>? row = await _client
        .from('lend_borrow_log')
        .select()
        .eq('user_id', _requireUserId())
        .eq('garment_id', garmentId)
        .eq('returned', false)
        .order('date_out', ascending: false)
        .limit(1)
        .maybeSingle();

    return row == null ? null : LendingRecord.fromJson(row);
  }

  Future<void> syncForAvailability({
    required String memberId,
    required String garmentId,
    required GarmentAvailabilityStatus status,
    String? personName,
    DateTime? dateOut,
    DateTime? expectedReturnDate,
    String? notes,
  }) async {
    await _verifyGarmentOwnership(memberId: memberId, garmentId: garmentId);

    final LendingDirection? direction = switch (status) {
      GarmentAvailabilityStatus.lent => LendingDirection.lent,
      GarmentAvailabilityStatus.borrowed => LendingDirection.borrowed,
      _ => null,
    };

    if (direction == null) {
      await _closeActiveRecord(garmentId: garmentId);
      return;
    }

    final String cleanPerson = personName?.trim() ?? '';
    if (cleanPerson.isEmpty) {
      throw ArgumentError.value(
        personName,
        'personName',
        '${status.label} To/From is required.',
      );
    }

    final DateTime resolvedDateOut = _dateOnly(dateOut ?? DateTime.now());
    final DateTime? resolvedExpectedReturn = expectedReturnDate == null
        ? null
        : _dateOnly(expectedReturnDate);

    if (resolvedExpectedReturn != null &&
        resolvedExpectedReturn.isBefore(resolvedDateOut)) {
      throw ArgumentError.value(
        expectedReturnDate,
        'expectedReturnDate',
        'Expected return date cannot be before the lent date.',
      );
    }

    final LendingRecord? active = await fetchActiveRecord(
      memberId: memberId,
      garmentId: garmentId,
    );

    final Map<String, dynamic> values = <String, dynamic>{
      'direction': direction.name,
      'person_name': cleanPerson,
      'date_out': _dateOnlyString(resolvedDateOut),
      'expected_return_date': resolvedExpectedReturn == null
          ? null
          : _dateOnlyString(resolvedExpectedReturn),
      'notes': _optional(notes),
      'returned': false,
      'returned_date': null,
    };

    if (active != null && active.direction == direction) {
      await _client
          .from('lend_borrow_log')
          .update(values)
          .eq('id', active.id)
          .eq('user_id', _requireUserId());
      return;
    }

    await _closeActiveRecord(garmentId: garmentId);

    await _client.from('lend_borrow_log').insert(<String, dynamic>{
      ...values,
      'user_id': _requireUserId(),
      'garment_id': garmentId,
    });
  }

  Future<void> markReturned({
    required String memberId,
    required String garmentId,
  }) async {
    await _verifyGarmentOwnership(memberId: memberId, garmentId: garmentId);
    final String userId = _requireUserId();
    final String today = _dateOnlyString(DateTime.now());

    await _client
        .from('lend_borrow_log')
        .update(<String, dynamic>{
          'returned': true,
          'returned_date': today,
        })
        .eq('user_id', userId)
        .eq('garment_id', garmentId)
        .eq('returned', false);

    await _client
        .from('garments')
        .update(<String, dynamic>{'availability_status': 'available'})
        .eq('id', garmentId)
        .eq('user_id', userId)
        .eq('member_id', memberId);
  }

  Future<void> _closeActiveRecord({required String garmentId}) async {
    await _client
        .from('lend_borrow_log')
        .update(<String, dynamic>{
          'returned': true,
          'returned_date': _dateOnlyString(DateTime.now()),
        })
        .eq('user_id', _requireUserId())
        .eq('garment_id', garmentId)
        .eq('returned', false);
  }

  Future<void> _verifyGarmentOwnership({
    required String memberId,
    required String garmentId,
  }) async {
    final Map<String, dynamic>? row = await _client
        .from('garments')
        .select('id')
        .eq('id', garmentId)
        .eq('user_id', _requireUserId())
        .eq('member_id', memberId)
        .maybeSingle();

    if (row == null) {
      throw StateError('Garment not found for this profile.');
    }
  }

  String? _optional(String? value) {
    final String trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  String _dateOnlyString(DateTime date) {
    final DateTime clean = _dateOnly(date);
    return '${clean.year}-'
        '${clean.month.toString().padLeft(2, '0')}-'
        '${clean.day.toString().padLeft(2, '0')}';
  }

  String _requireUserId() {
    final User? currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw StateError('No authenticated user.');
    }

    return currentUser.id;
  }
}
