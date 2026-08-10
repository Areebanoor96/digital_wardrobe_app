import 'package:digital_wardrobe_app/app.dart';
import 'package:digital_wardrobe_app/core/config/supabase_config.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

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

  runApp(const ProviderScope(child: DigitalWardrobeApp()));
}

