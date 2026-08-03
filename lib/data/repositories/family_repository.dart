import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FamilyRepository {
  FamilyRepository(this._client);

  final SupabaseClient _client;
  static const String _avatarBucket = 'profile_avatars';

  Future<List<FamilyMember>> fetchFamilyMembers() async {
    final List<dynamic> rows = await _client
        .from('family_members')
        .select()
        .order('created_at');

    return Future.wait(
      rows.map(
            (dynamic row) =>
            _withSignedAvatarUrl(Map<String, dynamic>.from(row as Map)),
      ),
    );
  }
  Future<FamilyMember> _addSignedAvatarUrl(
      FamilyMember member,
      ) async {
    final String? avatarPath = member.avatarPath;

    if (avatarPath == null || avatarPath.trim().isEmpty) {
      return member;
    }

    try {
      final String signedUrl = await _client.storage
          .from(_avatarBucket)
          .createSignedUrl(avatarPath, 86400);

      return member.copyWith(
        avatarUrl: signedUrl,
      );
    } catch (error) {
      debugPrint(
        'Avatar failed for ${member.name}: '
            'bucket=$_avatarBucket, path=$avatarPath, error=$error',
      );

      return member.copyWith(
        avatarUrl: null,
      );
    }
  }
  Future<FamilyMember> addFamilyMember({
    required String name,
    required String relationship,
    Uint8List? avatarBytes,
    DateTime? birthDate,
    double? heightCm,
    double? weightKg,
    String? currentSize,
  }) async {
    final String userId = _client.auth.currentUser!.id;

    final Map<String, dynamic> row = Map<String, dynamic>.from(
      await _client
              .from('family_members')
              .insert({
                'user_id': userId,
                'name': name,
                'relationship': relationship,
                'birth_date': birthDate?.toIso8601String().split('T').first,
                'height_cm': heightCm,
                'weight_kg': weightKg,
                'current_size': currentSize,
              })
              .select()
              .single()
          as Map,
    );
    FamilyMember member = FamilyMember.fromJson(row);
    if (avatarBytes == null) {
      return member;
    }
    final String avatarPath = await uploadAvatar(
      memberId: member.id,
      bytes: avatarBytes,
    );
    await updateAvatarPath(
      memberId: member.id,
      avatarPath: avatarPath,
    );
    member = member.copyWith(
      avatarPath: avatarPath,
    );
    return _addSignedAvatarUrl(member);
  }

  Future<void> deleteFamilyMember(FamilyMember member) async {
    final User? currentUser = _client.auth.currentUser;

    if (currentUser == null) {
      throw StateError('No authenticated user.');
    }

    // Delete the database record first.
    // Related wardrobe data is removed by ON DELETE CASCADE.
    await _client
        .from('family_members')
        .delete()
        .eq('id', member.id)
        .eq('user_id', currentUser.id);

    // Avatar cleanup is best-effort and must not undo profile deletion.
    final String? avatarPath = member.avatarPath?.trim();

    if (avatarPath == null || avatarPath.isEmpty) {
      return;
    }

    try {
      await _client.storage.from(_avatarBucket).remove(<String>[avatarPath]);
    } on StorageException catch (error) {
      debugPrint(
        'Profile deleted, but avatar cleanup failed: ${error.message}',
      );
    }
  }

  Future<void> updateFamilyMember({
    required String id,
    required String name,
    required String relationship,
  }) async {
    await _client
        .from('family_members')
        .update({'name': name, 'relationship': relationship})
        .eq('id', id);
  }

  Future<FamilyMember?> getFamilyMemberById(String id) async {
    final response = await _client
        .from('family_members')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return _withSignedAvatarUrl(
      Map<String, dynamic>.from(response as Map),
    );
  }
  Future<String> uploadAvatar({
    required String memberId,
    required Uint8List bytes,
  }) async {
    final String userId = _client.auth.currentUser!.id;
    final String path = '$userId/$memberId/avatar.jpg';

    await _client.storage
        .from(_avatarBucket)
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
  Future<void> updateAvatarPath({
    required String memberId,
    required String? avatarPath,
  }) async {
    final String userId = _client.auth.currentUser!.id;

    await _client
        .from('family_members')
        .update({'avatar_path': avatarPath})
        .eq('id', memberId)
        .eq('user_id', userId);
  }
  Future<FamilyMember> _withSignedAvatarUrl(
      Map<String, dynamic> row,
      ) async {
    final FamilyMember member = FamilyMember.fromJson(row);

    return _addSignedAvatarUrl(member);
  }
  Future<void> updateAvatar({
    required String memberId,
    required Uint8List bytes,
  }) async {
    final avatarPath = await uploadAvatar(
      memberId: memberId,
      bytes: bytes,
    );

    await updateAvatarPath(
      memberId: memberId,
      avatarPath: avatarPath,
    );
  }
  Future<void> removeAvatar(
      FamilyMember member,
      ) async {
    if (member.avatarPath == null) return;

    await _client.storage
        .from(_avatarBucket)
        .remove([member.avatarPath!]);

    await updateAvatarPath(
      memberId: member.id,
      avatarPath: null,
    );
  }
}
