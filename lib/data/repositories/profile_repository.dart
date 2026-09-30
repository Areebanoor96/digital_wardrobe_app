import 'dart:io';
import 'package:digital_wardrobe_app/data/models/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  ProfileRepository(this._client);
  final SupabaseClient _client;

  /// Fetches the user's profile and converts the storage avatar path into a signed URL
  Future<Profile> fetchProfile() async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    final profile = Profile.fromJson(Map<String, dynamic>.from(data as Map));

    // If an avatar path exists, generate a signed URL for display
    if (profile.avatarPath != null && profile.avatarPath!.isNotEmpty) {
      final signedUrl = await getAvatarSignedUrl(profile.avatarPath!);
      return profile.copyWith(avatarUrl: signedUrl);
    }

    return profile;
  }

  /// Generates a signed URL from the storage bucket
  Future<String?> getAvatarSignedUrl(String path) async {
    try {
      return await _client.storage
          .from('profile_avatars')
          .createSignedUrl(path, 60 * 60 * 24 * 7); // 7 days validity
    } catch (_) {
      return null;
    }
  }

  /// Uploads an avatar image to storage and updates `avatar_path` in the profiles table
  Future<String> uploadAvatar(File file) async {
    final userId = _client.auth.currentUser!.id;
    final fileExt = file.path.split('.').last;
    final path = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    await _client.storage.from('profile_avatars').upload(
      path,
      file,
      fileOptions: const FileOptions(upsert: true),
    );

    await _client
        .from('profiles')
        .update(<String, dynamic>{'avatar_path': path})
        .eq('id', userId);

    return path;
  }

  /// Updates primary user profile details
  Future<void> updateProfileDetails({
    required String fullName,
    required String username,
    String? pronouns,
    String? gender,
  }) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('profiles').update(<String, dynamic>{
      'full_name': fullName,
      'username': username.toLowerCase().trim(),
      'pronouns': pronouns,
      'gender': gender,
    }).eq('id', userId);
  }

  /// Settings and preference toggles
  Future<void> updateGrowthAlertsEnabled(bool enabled) => _client
      .from('profiles')
      .update(<String, bool>{'growth_alerts_enabled': enabled})
      .eq('id', _client.auth.currentUser!.id);

  Future<void> updateLocationCity(String? city) => _client
      .from('profiles')
      .update(<String, String?>{'location_city': city})
      .eq('id', _client.auth.currentUser!.id);

  Future<void> updateCountryCode(String? countryCode) => _client
      .from('profiles')
      .update(<String, String?>{'country_code': countryCode})
      .eq('id', _client.auth.currentUser!.id);

  Future<void> updateAlertPreferences({
    required bool unusedAlertsEnabled,
    required bool laundryAlertsEnabled,
    required bool ootdAlertsEnabled,
    bool? growthAlertsEnabled,
  }) {
    return _client
        .from('profiles')
        .update(<String, dynamic>{
      'unused_alerts_enabled': unusedAlertsEnabled,
      'laundry_alerts_enabled': laundryAlertsEnabled,
      'ootd_alerts_enabled': ootdAlertsEnabled,
      if (growthAlertsEnabled != null)
        'growth_alerts_enabled': growthAlertsEnabled,
    }).eq('id', _client.auth.currentUser!.id);
  }
}