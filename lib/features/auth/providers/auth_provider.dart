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

  Future<AuthResponse> signUp(
      String name,
      String email,
      String password,
      ) {
    return SupabaseService.client.auth.signUp(
      email: email,
      password: password,
      data: <String, dynamic>{
        'full_name': name,
      },
    );
  }

  Future<void> signInWithProvider(OAuthProvider provider) {
    return SupabaseService.client.auth.signInWithOAuth(
      provider,
      redirectTo:
      'com.example.digitalwardrobeapp://login-callback/',
    );
  }

  Future<void> signOut() {
    return SupabaseService.client.auth.signOut();
  }

  Future<void> sendPasswordResetOtp(String email) {
    return SupabaseService.client.auth.resetPasswordForEmail(
      email,
    );
  }
  Future<AuthResponse> verifyPasswordResetOtp(
      String email,
      String token,
      ) {
    return SupabaseService.client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.recovery,
    );
  }
  Future<UserResponse> updatePassword(String newPassword) {
    return SupabaseService.client.auth.updateUser(
      UserAttributes(
        password: newPassword,
      ),
    );
  }

  Future<AuthResponse> verifyEmailOtp(
      String email,
      String token,
      ) {
    return SupabaseService.client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
  }

  Future<ResendResponse> resendSignupOtp(String email) {
    return SupabaseService.client.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }
}

final Provider<AuthController> authControllerProvider =
    Provider<AuthController>((Ref ref) => const AuthController());
