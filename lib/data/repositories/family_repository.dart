import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FamilyRepository {

  FamilyRepository(this._client);

  final SupabaseClient _client;


  Future<List<FamilyMember>> fetchFamilyMembers() async {

    final List<dynamic> rows = await _client
        .from('family_members')
        .select()
        .order('created_at');


    return rows
        .map(
          (dynamic row) =>
          FamilyMember.fromJson(
            Map<String,dynamic>.from(row as Map),
          ),
    )
        .toList();
  }


  Future<FamilyMember> addFamilyMember({
    required String name,
    required String relationship,
    DateTime? birthDate,
    double? heightCm,
    double? weightKg,
    String? currentSize,
  }) async {

    final String userId =
        _client.auth.currentUser!.id;


    final Map<String,dynamic> row =
    Map<String,dynamic>.from(
      await _client
          .from('family_members')
          .insert({
        'user_id': userId,
        'name': name,
        'relationship': relationship,
        'birth_date': birthDate
            ?.toIso8601String()
            .split('T')
            .first,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'current_size': currentSize,
      })
          .select()
          .single()
      as Map,
    );

    return FamilyMember.fromJson(row);
  }
  Future<void> deleteFamilyMember(String id) async {

    await _client
        .from('family_members')
        .delete()
        .eq('id', id);

  }
  Future<void> updateFamilyMember({
    required String id,
    required String name,
    required String relationship,
  }) async {

    await _client
        .from('family_members')
        .update({
      'name': name,
      'relationship': relationship,
    })
        .eq('id', id);

  }
}