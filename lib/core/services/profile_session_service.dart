import 'package:shared_preferences/shared_preferences.dart';

class ProfileSessionService {
  static const _selectedProfileKey = 'selected_profile_id';

  static Future<void> saveSelectedProfile(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedProfileKey, profileId);
  }

  static Future<String?> getSelectedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedProfileKey);
  }

  static Future<void> clearSelectedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedProfileKey);
  }
}
