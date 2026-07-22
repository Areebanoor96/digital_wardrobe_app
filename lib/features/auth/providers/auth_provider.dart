import 'package:digital_wardrobe_app/core/config/supabase_config.dart';
import 'package:digital_wardrobe_app/core/services/supabase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final StreamProvider<AuthState> authStateProvider = StreamProvider<AuthState>((
  Ref ref,
) {
  if (!SupabaseConfig.isConfigured) return const Stream<AuthState>.empty();
  return SupabaseService.client.auth.onAuthStateChange;
});

class AuthController {
  const AuthController();

  Future<void> signInWithEmail(String email, String password) {
    return SupabaseService.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUp(String name, String email, String password) {
    return SupabaseService.client.auth.signUp(
      email: email,
      password: password,
      data: <String, dynamic>{'full_name': name},
    );
  }

  Future<void> signInWithProvider(OAuthProvider provider) {
    return SupabaseService.client.auth.signInWithOAuth(
      provider,
      redirectTo: 'io.supabase.digitalwardrobe://login-callback/',
    );
  }

  Future<void> sendPasswordReset(String email) {
    return SupabaseService.client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'io.supabase.digitalwardrobe://login-callback/',
    );
  }
}

final Provider<AuthController> authControllerProvider =
    Provider<AuthController>((Ref ref) => const AuthController());
