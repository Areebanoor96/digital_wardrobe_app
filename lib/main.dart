import 'package:digital_wardrobe_app/app.dart';
import 'package:digital_wardrobe_app/core/config/supabase_config.dart';
import 'package:digital_wardrobe_app/core/providers/theme_provider.dart';
import 'package:digital_wardrobe_app/core/services/theme_preference_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
  }

    final ImagePickerPlatform pickerImplementation =
        ImagePickerPlatform.instance;

    if (pickerImplementation is ImagePickerAndroid) {
      pickerImplementation.useAndroidPhotoPicker = true;
    }

  final bool darkModeEnabled = await ThemePreferenceService.isDarkModeEnabled();

  runApp(ProviderScope(
    overrides: <Override>[
      themeModeProvider.overrideWith(
        (final ref) => darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
      ),
    ],
    child: const DigitalWardrobeApp(),
  ));
}

