import 'package:digital_wardrobe_app/data/models/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  ProfileRepository(this._client);
  final SupabaseClient _client;

  Future<Profile> fetchProfile() async => Profile.fromJson(
    Map<String, dynamic>.from(
      await _client
              .from('profiles')
              .select()
              .eq('id', _client.auth.currentUser!.id)
              .single()
          as Map,
    ),
  );
  Future<void> updateName(String name) => _client
      .from('profiles')
      .update(<String, String>{'full_name': name})
      .eq('id', _client.auth.currentUser!.id);
  Future<void> updateAlertPreferences({
    required bool unusedAlertsEnabled,
    required bool laundryAlertsEnabled,
    required bool ootdAlertsEnabled,
  }) {
    return _client
        .from('profiles')
        .update(<String, bool>{
      'unused_alerts_enabled': unusedAlertsEnabled,
      'laundry_alerts_enabled': laundryAlertsEnabled,
      'ootd_alerts_enabled': ootdAlertsEnabled,
    })
        .eq('id', _client.auth.currentUser!.id);
  }
}
