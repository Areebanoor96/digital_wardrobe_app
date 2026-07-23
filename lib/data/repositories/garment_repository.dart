import 'dart:typed_data';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GarmentRepository {
  GarmentRepository(this._client);

  final SupabaseClient _client;
  static const String _bucket = 'garments';

  Future<List<Garment>> fetchGarments({
    String? memberId,
  }) async {

    var query = _client
        .from('garments')
        .select()
        .eq('is_archived', false);


    if (memberId != null) {
      query = query.eq(
        'member_id',
        memberId,
      );
    }


    final List<dynamic> rows =
    await query.order(
      'created_at',
      ascending: false,
    );


    return Future.wait(
      rows.map(
            (dynamic row) =>
            _withSignedUrls(
              Map<String,dynamic>.from(
                row as Map,
              ),
            ),
      ),
    );
  }

  Future<Garment> fetchGarment(String id) async {
    final Map<String, dynamic> row = Map<String, dynamic>.from(
      await _client.from('garments').select().eq('id', id).single() as Map,
    );
    return _withSignedUrls(row);
  }

  Future<Garment> saveGarment(Garment garment, {required bool isNew}) async {
    final String userId = _client.auth.currentUser!.id;
    final Map<String, dynamic> row;
    if (isNew) {
      row = Map<String, dynamic>.from(
        await _client
                .from('garments')
                .insert(garment.toInsertJson(userId))
                .select()
                .single()
            as Map,
      );
    } else {
      row = Map<String, dynamic>.from(
        await _client
                .from('garments')
                .update(garment.toInsertJson(userId))
                .eq('id', garment.id)
                .select()
                .single()
            as Map,
      );
    }
    return _withSignedUrls(row);
  }

  Future<String> uploadImage({
    required String garmentId,
    required Uint8List bytes,
  }) async {
    final String userId = _client.auth.currentUser!.id;
    final String path = '$userId/$garmentId/cover.jpg';
    await _client.storage
        .from(_bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
    return path;
  }

  Future<void> archiveGarment(String garmentId) async {
    await _client
        .from('garments')
        .update(<String, bool>{'is_archived': true})
        .eq('id', garmentId);
  }

  Future<Garment> _withSignedUrls(Map<String, dynamic> row) async {
    final Garment garment = Garment.fromJson(row);
    if (garment.photoPaths.isEmpty) return garment;
    final List<String> urls =
        (await _client.storage
                .from(_bucket)
                .createSignedUrlsResult(garment.photoPaths, 3600))
            .whereType<SignedUrlSuccess>()
            .map((SignedUrlSuccess result) => result.signedUrl)
            .toList();
    return garment.copyWith(photoUrls: urls);
  }
}
