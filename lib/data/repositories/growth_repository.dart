import 'package:digital_wardrobe_app/data/models/growth_measurement.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GrowthRepository {
  GrowthRepository(this._client);

  final SupabaseClient _client;

  Future<List<GrowthMeasurement>> fetchMeasurements({
    required String memberId,
  }) async {
    final String userId = _client.auth.currentUser!.id;

    final List<dynamic> rows = await _client
        .from('growth_measurements')
        .select()
        .eq('user_id', userId)
        .eq('member_id', memberId)
        .order('recorded_at', ascending: false);

    return rows
        .map(
          (dynamic row) =>
              GrowthMeasurement.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<GrowthMeasurement?> fetchLatestMeasurement({
    required String memberId,
  }) async {
    final String userId = _client.auth.currentUser!.id;

    final Map<String, dynamic>? row = await _client
        .from('growth_measurements')
        .select()
        .eq('user_id', userId)
        .eq('member_id', memberId)
        .order('recorded_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (row == null) {
      return null;
    }

    return GrowthMeasurement.fromJson(row);
  }

  Future<GrowthMeasurement> addMeasurement({
    required String memberId,
    required DateTime recordedAt,
    double? heightCm,
    double? weightKg,
    String? clothingSize,
    String? shoeSize,
    double? footLengthCm,
  }) async {
    final String userId = _client.auth.currentUser!.id;

    final Map<String, dynamic> values = <String, dynamic>{
      'user_id': userId,
      'member_id': memberId,
      'recorded_at': recordedAt.toIso8601String().split('T').first,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'clothing_size': clothingSize,
      'shoe_size': shoeSize,
      'foot_length_cm': footLengthCm,
    };

    final Map<String, dynamic> row = Map<String, dynamic>.from(
      await _client.from('growth_measurements').insert(values).select().single()
          as Map,
    );

    await _syncCurrentMeasurements(memberId: memberId);

    return GrowthMeasurement.fromJson(row);
  }

  Future<void> deleteMeasurement({
    required String measurementId,
    required String memberId,
  }) async {
    final String userId = _client.auth.currentUser!.id;

    await _client
        .from('growth_measurements')
        .delete()
        .eq('id', measurementId)
        .eq('user_id', userId);

    await _syncCurrentMeasurements(memberId: memberId);
  }

  Future<void> _syncCurrentMeasurements({required String memberId}) async {
    final String userId = _client.auth.currentUser!.id;

    final List<dynamic> rows = await _client
        .from('growth_measurements')
        .select()
        .eq('user_id', userId)
        .eq('member_id', memberId)
        .order('recorded_at', ascending: false)
        .order('created_at', ascending: false);

    if (rows.isEmpty) {
      return;
    }

    double? heightCm;
    double? weightKg;
    String? clothingSize;
    String? shoeSize;
    double? footLengthCm;

    for (final dynamic rawRow in rows) {
      final Map<String, dynamic> row = Map<String, dynamic>.from(rawRow as Map);

      heightCm ??= (row['height_cm'] as num?)?.toDouble();
      weightKg ??= (row['weight_kg'] as num?)?.toDouble();
      clothingSize ??= row['clothing_size'] as String?;
      shoeSize ??= row['shoe_size'] as String?;
      footLengthCm ??= (row['foot_length_cm'] as num?)?.toDouble();

      if (heightCm != null &&
          weightKg != null &&
          clothingSize != null &&
          shoeSize != null &&
          footLengthCm != null) {
        break;
      }
    }

    await _client
        .from('family_members')
        .update(<String, dynamic>{
          'height_cm': heightCm,
          'weight_kg': weightKg,
          'current_size': clothingSize,
          'shoe_size': shoeSize,
          'foot_length_cm': footLengthCm,
        })
        .eq('id', memberId)
        .eq('user_id', userId);
  }
}
