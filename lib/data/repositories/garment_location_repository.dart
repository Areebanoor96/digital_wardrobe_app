import 'package:digital_wardrobe_app/data/models/garment_location.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class GarmentLocationRepository {
  GarmentLocationRepository(this._client);

  final SupabaseClient _client;

  Future<List<GarmentLocation>> fetchLocations({
    required String memberId,
  }) async {
    final List<dynamic> rows = await _client
        .from('garment_locations')
        .select()
        .eq('user_id', _requireUserId())
        .eq('member_id', memberId)
        .order('name');

    return rows
        .map(
          (dynamic row) =>
              GarmentLocation.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<GarmentLocation> createLocation({
    required String memberId,
    required String name,
  }) async {
    final String trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Location name is required.');
    }

    final Map<String, dynamic> row = Map<String, dynamic>.from(
      await _client
              .from('garment_locations')
              .insert(<String, dynamic>{
                'id': const Uuid().v4(),
                'user_id': _requireUserId(),
                'member_id': memberId,
                'name': trimmedName,
              })
              .select()
              .single()
          as Map,
    );

    return GarmentLocation.fromJson(row);
  }

  Future<void> renameLocation({
    required String memberId,
    required String locationId,
    required String name,
  }) async {
    final String trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Location name is required.');
    }

    await _client
        .from('garment_locations')
        .update(<String, dynamic>{'name': trimmedName})
        .eq('id', locationId)
        .eq('user_id', _requireUserId())
        .eq('member_id', memberId);
  }

  Future<void> deleteLocation({
    required String memberId,
    required String locationId,
  }) async {
    final String userId = _requireUserId();

    final List<dynamic> garmentRows = await _client
        .from('garments')
        .select('id')
        .eq('user_id', userId)
        .eq('member_id', memberId)
        .eq('location_id', locationId)
        .limit(1);

    if (garmentRows.isNotEmpty) {
      throw StateError('Move garments out of this location before deleting it.');
    }

    await _client
        .from('garment_locations')
        .delete()
        .eq('id', locationId)
        .eq('user_id', userId)
        .eq('member_id', memberId);
  }

  String _requireUserId() {
    final User? currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw StateError('No authenticated user.');
    }

    return currentUser.id;
  }
}
