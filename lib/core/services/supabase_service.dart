import 'package:digital_wardrobe_app/core/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  const SupabaseService._();

  static SupabaseClient get client {
    if (!SupabaseConfig.isConfigured) {
      throw StateError('Supabase credentials have not been configured.');
    }
    return Supabase.instance.client;
  }
}
