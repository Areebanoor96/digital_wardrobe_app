import 'dart:typed_data';

import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GarmentRepository {
  GarmentRepository(this._client);

  final SupabaseClient _client;

  static const String _bucket = 'garments';
  static const String _garmentSelect =
      '*, garment_color_shades(*), garment_sizes(*), garment_locations(name)';

  Future<List<Garment>> fetchGarments({required String memberId}) async {
    final List<dynamic> rows = await _client
        .from('garments')
        .select(_garmentSelect)
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
        .select(_garmentSelect)
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
              .select(_garmentSelect)
              .eq('id', id)
              .eq('member_id', memberId)
              .single()
          as Map,
    );

    return _withSignedUrls(row);
  }

  Future<List<Garment>> fetchGarmentsByIds({
    required String memberId,
    required List<String> garmentIds,
  }) async {
    if (garmentIds.isEmpty) {
      return const <Garment>[];
    }

    final List<dynamic> rows = await _client
        .from('garments')
        .select(_garmentSelect)
        .eq('member_id', memberId)
        .inFilter('id', garmentIds);

    final List<Garment> garments = await Future.wait(
      rows.map(
        (dynamic row) => _withSignedUrls(Map<String, dynamic>.from(row as Map)),
      ),
    );
    final Map<String, Garment> byId = <String, Garment>{
      for (final Garment garment in garments) garment.id: garment,
    };

    return garmentIds
        .map((String id) => byId[id])
        .whereType<Garment>()
        .toList();
  }

  Future<Garment> saveGarment(Garment garment, {required bool isNew}) async {
    final User? currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw StateError('Cannot save garment without an authenticated user.');
    }

    final String userId = currentUser.id;
    final Map<String, dynamic> row;

    if (isNew) {
      final Map<String, dynamic> inserted = Map<String, dynamic>.from(
        await _client
                .from('garments')
                .insert(garment.toInsertJson(userId))
                .select()
                .single()
            as Map,
      );
      await _syncColorShades(garment, userId: userId);
      await _syncSizes(garment, userId: userId);
      row = await _fetchSavedRow(inserted['id'] as String, garment.memberId);
    } else {
      final String garmentId = garment.id;
      final String? memberId = garment.memberId;

      if (memberId == null) {
        throw StateError('Cannot update a garment without a member ID.');
      }

      await _client
          .from('garments')
          .update(garment.toInsertJson(userId))
          .eq('id', garmentId)
          .eq('member_id', memberId);

      await _syncColorShades(garment, userId: userId);
      await _syncSizes(garment, userId: userId);
      row = await _fetchSavedRow(garmentId, memberId);
    }

    return _withSignedUrls(row);
  }

  Future<Map<String, dynamic>> _fetchSavedRow(
    String garmentId,
    String? memberId,
  ) async {
    if (memberId == null) {
      return Map<String, dynamic>.from(
        await _client
                .from('garments')
                .select(_garmentSelect)
                .eq('id', garmentId)
                .single()
            as Map,
      );
    }

    return Map<String, dynamic>.from(
      await _client
              .from('garments')
              .select(_garmentSelect)
              .eq('id', garmentId)
              .eq('member_id', memberId)
              .single()
          as Map,
    );
  }

  Future<void> _syncColorShades(
    Garment garment, {
    required String userId,
  }) async {
    final List<GarmentColorShade> shades = normalizeColorShades(
      garment.colorShades,
    );

    await _client
        .from('garment_color_shades')
        .delete()
        .eq('garment_id', garment.id);

    if (shades.isEmpty) {
      return;
    }

    await _client.from('garment_color_shades').insert(
      <Map<String, dynamic>>[
        for (int index = 0; index < shades.length; index++)
          shades[index].toJson(
            userId: userId,
            garmentId: garment.id,
            sortOrder: index,
          ),
      ],
    );
  }

  Future<void> _syncSizes(
    Garment garment, {
    required String userId,
  }) async {
    final List<String> sizes = _normalizeSizes(garment.effectiveSizes);

    await _client
        .from('garment_sizes')
        .delete()
        .eq('garment_id', garment.id)
        .eq('user_id', userId);

    if (sizes.isEmpty) {
      return;
    }

    await _client.from('garment_sizes').insert(
      <Map<String, dynamic>>[
        for (int index = 0; index < sizes.length; index++)
          <String, dynamic>{
            'user_id': userId,
            'garment_id': garment.id,
            'size': sizes[index],
            'sort_order': index,
          },
      ],
    );
  }

  List<String> _normalizeSizes(List<String> values) {
    final List<String> result = <String>[];
    final Set<String> seen = <String>{};

    for (final String value in values) {
      final String trimmed = value.trim();
      if (trimmed.isNotEmpty && seen.add(trimmed.toLowerCase())) {
        result.add(trimmed);
      }
    }

    return result;
  }

  Future<Map<String, int>> fetchActiveGarmentCountsByMember() async {
    final String userId = _client.auth.currentUser!.id;

    final List<dynamic> rows = await _client
        .from('garments')
        .select('member_id')
        .eq('user_id', userId)
        .eq('is_archived', false);

    final Map<String, int> counts = <String, int>{};
    for (final dynamic row in rows) {
      final String? memberId =
          Map<String, dynamic>.from(row as Map)['member_id'] as String?;
      if (memberId == null) {
        continue;
      }

      counts[memberId] = (counts[memberId] ?? 0) + 1;
    }

    return counts;
  }

  Future<void> _updateArchiveState({
    required String garmentId,
    required String memberId,
    required bool isArchived,
  }) async {
    final Map<String, dynamic>? row = await _client
        .from('garments')
        .update(<String, bool>{'is_archived': isArchived})
        .eq('id', garmentId)
        .eq('member_id', memberId)
        .select('id')
        .maybeSingle();

    if (row == null) {
      throw StateError(
        'No garment was updated. Check selected profile ownership.',
      );
    }
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
    await _updateArchiveState(
      garmentId: garmentId,
      memberId: memberId,
      isArchived: true,
    );
  }

  Future<void> restoreGarment({
    required String garmentId,
    required String memberId,
  }) async {
    await _updateArchiveState(
      garmentId: garmentId,
      memberId: memberId,
      isArchived: false,
    );
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
