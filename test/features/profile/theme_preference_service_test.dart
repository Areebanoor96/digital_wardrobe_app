import 'package:digital_wardrobe_app/core/services/theme_preference_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('dark mode preference defaults to light and persists', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    expect(await ThemePreferenceService.isDarkModeEnabled(), isFalse);

    await ThemePreferenceService.setDarkModeEnabled(true);

    expect(await ThemePreferenceService.isDarkModeEnabled(), isTrue);

    await ThemePreferenceService.setDarkModeEnabled(false);

    expect(await ThemePreferenceService.isDarkModeEnabled(), isFalse);
  });
}