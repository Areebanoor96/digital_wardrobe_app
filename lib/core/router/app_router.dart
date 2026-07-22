import 'package:digital_wardrobe_app/data/models/outfit.dart';
import 'package:digital_wardrobe_app/features/auth/screens/auth_screen.dart';
import 'package:digital_wardrobe_app/features/auth/screens/onboarding_screen.dart';
import 'package:digital_wardrobe_app/features/auth/screens/setup_wizard_screen.dart';
import 'package:digital_wardrobe_app/features/auth/screens/splash_screen.dart';
import 'package:digital_wardrobe_app/features/garment_form/screens/garment_form_screen.dart';
import 'package:digital_wardrobe_app/features/outfits/screens/outfit_builder_screen.dart';
import 'package:digital_wardrobe_app/features/outfits/screens/outfit_detail_screen.dart';
import 'package:digital_wardrobe_app/features/shell/screens/app_shell_screen.dart';
import 'package:digital_wardrobe_app/features/wardrobe/screens/garment_detail_screen.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: <RouteBase>[
    GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
    GoRoute(path: '/auth', builder: (_, _) => const AuthScreen()),
    GoRoute(path: '/setup', builder: (_, _) => const SetupWizardScreen()),
    GoRoute(path: '/app', builder: (_, _) => const AppShellScreen()),
    GoRoute(
      path: '/garments/new',
      builder: (_, _) => const GarmentFormScreen(),
    ),
    GoRoute(
      path: '/garments/:id',
      builder: (_, GoRouterState state) =>
          GarmentDetailScreen(garmentId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/garments/:id/edit',
      builder: (_, GoRouterState state) =>
          GarmentFormScreen(garment: state.extra! as dynamic),
    ),
    GoRoute(
      path: '/outfits/new',
      builder: (_, _) => const OutfitBuilderScreen(),
    ),
    GoRoute(
      path: '/outfits/:id',
      builder: (_, GoRouterState state) =>
          OutfitDetailScreen(outfitId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/outfits/:id/edit',
      builder: (_, GoRouterState state) =>
          OutfitBuilderScreen(outfit: state.extra! as Outfit),
    ),
  ],
);
