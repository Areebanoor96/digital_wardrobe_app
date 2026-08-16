import 'dart:typed_data';

import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GarmentRepository {
  GarmentRepository(this._client);

  final SupabaseClient _client;

  static const String _bucket = 'garments';

  Future<List<Garment>> fetchGarments({required String memberId}) async {
    final List<dynamic> rows = await _client
        .from('garments')
        .select()
        .eq('is_archived', false)
        .eq('member_id', memberId)
        .order('created_at', ascending: false);

    return Future.wait(
      rows.map(
        (dynamic row) => _withSignedUrls(Map<String, dynamic>.from(row as Map)),
      ),
    );
  }

  Future<List<Garment>> fetchArchivedGarments({
    required String memberId,
  }) async {
    final List<dynamic> rows = await _client
        .from('garments')
        .select()
        .eq('is_archived', true)
        .eq('member_id', memberId)
        .order('created_at', ascending: false);

    return Future.wait(
      rows.map(
        (dynamic row) => _withSignedUrls(Map<String, dynamic>.from(row as Map)),
      ),
    );
  }

  Future<Garment> fetchGarment({
    required String id,
    required String memberId,
  }) async {
    final Map<String, dynamic> row = Map<String, dynamic>.from(
      await _client
              .from('garments')
              .select()
              .eq('id', id)
              .eq('member_id', memberId)
              .single()
          as Map,
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
      final String? garmentId = garment.id;
      final String? memberId = garment.memberId;

      if (garmentId == null) {
        throw StateError('Cannot update a garment without an ID.');
      }

      if (memberId == null) {
        throw StateError('Cannot update a garment without a member ID.');
      }

      row = Map<String, dynamic>.from(
        await _client
                .from('garments')
                .update(garment.toInsertJson(userId))
                .eq('id', garmentId)
                .eq('member_id', memberId)
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
    required int imageIndex,
  }) async {
    final String userId = _client.auth.currentUser!.id;
    final int timestamp = DateTime.now().microsecondsSinceEpoch;

    final String path = '$userId/$garmentId/photo_${timestamp}_$imageIndex.jpg';

    await _client.storage
        .from(_bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ),
        );

    return path;
  }

  Future<void> deleteImages(List<String> paths) async {
    if (paths.isEmpty) {
      return;
    }

    await _client.storage.from(_bucket).remove(paths);
  }

  Future<void> archiveGarment({
    required String garmentId,
    required String memberId,
  }) async {
    await _client
        .from('garments')
        .update(<String, bool>{'is_archived': true})
        .eq('id', garmentId)
        .eq('member_id', memberId);
  }

  Future<void> restoreGarment({
    required String garmentId,
    required String memberId,
  }) async {
    await _client
        .from('garments')
        .update(<String, bool>{'is_archived': false})
        .eq('id', garmentId)
        .eq('member_id', memberId);
  }

  Future<Garment> _withSignedUrls(Map<String, dynamic> row) async {
    final Garment garment = Garment.fromJson(row);

    if (garment.photoPaths.isEmpty) {
      return garment;
    }

    final List<String> urls = await Future.wait(
      garment.photoPaths.map((String path) async {
        try {
          final String signedUrl = await _client.storage
              .from(_bucket)
              .createSignedUrl(path, 3600);

          return signedUrl;
        } catch (_) {
          // Preserve list order/index alignment even if one image fails.
          return '';
        }
      }),
    );

    return garment.copyWith(photoUrls: urls);
  }
}
