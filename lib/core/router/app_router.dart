import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/core/services/supabase_service.dart';
import 'package:digital_wardrobe_app/data/models/outfit.dart';
import 'package:digital_wardrobe_app/features/auth/screens/verify_email_screen.dart';
import 'package:digital_wardrobe_app/features/auth/screens/auth_screen.dart';
import 'package:digital_wardrobe_app/features/auth/screens/onboarding_screen.dart';
import 'package:digital_wardrobe_app/features/auth/screens/setup_wizard_screen.dart';
import 'package:digital_wardrobe_app/features/auth/screens/splash_screen.dart';
import 'package:digital_wardrobe_app/features/garment_form/screens/garment_form_screen.dart';
import 'package:digital_wardrobe_app/features/outfits/screens/outfit_builder_screen.dart';
import 'package:digital_wardrobe_app/features/outfits/screens/outfit_detail_screen.dart';
import 'package:digital_wardrobe_app/features/profile/screens/profile_selection_screen.dart';
import 'package:digital_wardrobe_app/features/shell/screens/app_shell_screen.dart';
import 'package:digital_wardrobe_app/features/wardrobe/screens/garment_detail_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_wardrobe_app/features/wardrobe/screens/archived_garments_screen.dart';
import 'package:digital_wardrobe_app/features/auth/screens/forgot_password_screen.dart';
import 'package:digital_wardrobe_app/features/auth/screens/reset_password_otp_screen.dart';
import 'package:digital_wardrobe_app/features/auth/screens/new_password_screen.dart';
import 'package:go_router/go_router.dart';

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((Ref ref) {
  return GoRouter(
    initialLocation: '/splash',

    redirect: (context, state) {
      final bool signedIn = SupabaseService.client.auth.currentSession != null;

      final selectedMember = ref.read(selectedFamilyMemberProvider);

      final String location = state.matchedLocation;

      final bool isPublicRoute =
          location == '/splash' ||
          location == '/onboarding' ||
          location == '/auth'||
          location == '/verify-email'||
              location == '/forgot-password' ||
              location == '/reset-password-otp' ||
              location == '/new-password';

      final bool isProfileRoute =
          location == '/profiles' || location == '/setup';

      if (!signedIn && !isPublicRoute) {
        return '/auth';
      }

      if (signedIn &&
          selectedMember == null &&
          !isPublicRoute &&
          !isProfileRoute) {
        return '/profiles';
      }

      return null;
    },

    routes: <RouteBase>[
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/auth', builder: (_, _) => const AuthScreen()),
      GoRoute(
        path: '/verify-email',
        builder: (_, GoRouterState state) {
          final String email = state.extra! as String;

          return VerifyEmailScreen(
            email: email,
          );
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) =>
        const ForgotPasswordScreen(),
      ),

      GoRoute(
        path: '/reset-password-otp',
        builder: (_, GoRouterState state) {
          final String email =
          state.extra! as String;

          return ResetPasswordOtpScreen(
            email: email,
          );
        },
      ),

      GoRoute(
        path: '/new-password',
        builder: (_, _) =>
        const NewPasswordScreen(),
      ),
      GoRoute(path: '/setup', builder: (_, _) => const SetupWizardScreen()),
      GoRoute(
        path: '/profiles',
        builder: (_, _) => const ProfileSelectionScreen(),
      ),
      GoRoute(path: '/app', builder: (_, _) => const AppShellScreen()),
      GoRoute(
        path: '/garments/new',
        builder: (_, _) => const GarmentFormScreen(),
      ),
      GoRoute(
        path: '/garments/archived',
        builder: (_, _) => const ArchivedGarmentsScreen(),
      ),
      GoRoute(
        path: '/garments/:id',
        builder: (_, GoRouterState state) {
          return GarmentDetailScreen(garmentId: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/garments/:id/edit',
        builder: (_, GoRouterState state) {
          return GarmentFormScreen(garment: state.extra! as dynamic);
        },
      ),
      GoRoute(
        path: '/outfits/new',
        builder: (_, _) => const OutfitBuilderScreen(),
      ),
      GoRoute(
        path: '/outfits/:id',
        builder: (_, GoRouterState state) {
          return OutfitDetailScreen(outfitId: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/outfits/:id/edit',
        builder: (_, GoRouterState state) {
          return OutfitBuilderScreen(outfit: state.extra! as Outfit);
        },
      ),
    ],
  );
});
