import 'package:digital_wardrobe_app/data/models/outfit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OutfitRepository {
  OutfitRepository(this._client);

  final SupabaseClient _client;

  Future<List<Outfit>> fetchOutfits({
    required String memberId,
  }) async {
    final List<dynamic> rows = await _client
        .from('outfits')
        .select()
        .eq('member_id', memberId)
        .order('created_at', ascending: false);

    return _withLastWorn(
      rows,
      memberId: memberId,
    );
  }

  Future<Outfit> fetchOutfit({
    required String outfitId,
    required String memberId,
  }) async {
    final Map<String, dynamic> row = Map<String, dynamic>.from(
      await _client
          .from('outfits')
          .select()
          .eq('id', outfitId)
          .eq('member_id', memberId)
          .single()
      as Map,
    );

    final List<Outfit> outfits = await _withLastWorn(
      <dynamic>[row],
      memberId: memberId,
    );

    return outfits.single;
  }

  Future<void> saveOutfit({
    required String memberId,
    required String name,
    required List<String> garmentIds,
    String? occasion,
    String? coverPhotoUrl,
  }) async {
    await _client.from('outfits').insert(<String, dynamic>{
      'user_id': _client.auth.currentUser!.id,
      'member_id': memberId,
      'name': name,
      'garment_ids': garmentIds,
      'occasion': occasion,
      'cover_photo_url': coverPhotoUrl,
    });
  }

  Future<void> updateOutfit(
      Outfit outfit, {
        required String name,
        required List<String> garmentIds,
      }) async {
    await _client
        .from('outfits')
        .update(<String, dynamic>{
      'name': name,
      'garment_ids': garmentIds,
      'cover_photo_url': outfit.coverPhotoUrl,
    })
        .eq('id', outfit.id)
        .eq('member_id', outfit.memberId);
  }

  Future<void> deleteOutfit({
    required String outfitId,
    required String memberId,
  }) async {
    await _client
        .from('outfits')
        .delete()
        .eq('id', outfitId)
        .eq('member_id', memberId);
  }

  Future<void> incrementWearCount(Outfit outfit) async {
    await _client
        .from('outfits')
        .update(<String, int>{
      'times_worn': outfit.timesWorn + 1,
    })
        .eq('id', outfit.id)
        .eq('member_id', outfit.memberId);
  }

  Future<List<Outfit>> _withLastWorn(
      List<dynamic> rows, {
        required String memberId,
      }) async {
    if (rows.isEmpty) return const <Outfit>[];

    final List<Outfit> outfits = rows
        .map(
          (dynamic row) =>
          Outfit.fromJson(Map<String, dynamic>.from(row as Map)),
    )
        .toList();

    final List<dynamic> wearRows = await _client
        .from('wear_log')
        .select('outfit_id,worn_date')
        .eq('member_id', memberId)
        .inFilter(
      'outfit_id',
      outfits.map((Outfit outfit) => outfit.id).toList(),
    )
        .order('worn_date', ascending: false);

    final Map<String, DateTime> lastWorn = <String, DateTime>{};

    for (final dynamic row in wearRows) {
      final Map<String, dynamic> value =
      Map<String, dynamic>.from(row as Map);

      final String? outfitId = value['outfit_id'] as String?;

      if (outfitId != null && !lastWorn.containsKey(outfitId)) {
        lastWorn[outfitId] =
            DateTime.parse(value['worn_date'] as String);
      }
    }

    return outfits
        .map(
          (Outfit outfit) => outfit.copyWith(
        lastWornDate: lastWorn[outfit.id],
      ),
    )
        .toList();
  }
}