import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's dark-mode preference using the app's existing
/// [SharedPreferences] storage layer.
class ThemePreferenceService {
  static const _darkModeKey = 'dark_mode_enabled';

  static Future<bool> isDarkModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }

  static Future<void> setDarkModeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, enabled);
  }
}