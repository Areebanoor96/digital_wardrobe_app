import 'package:digital_wardrobe_app/core/config/supabase_config.dart';
import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/core/services/profile_session_service.dart';
import 'package:digital_wardrobe_app/core/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      debugPrint("SESSION: ${SupabaseService.client.auth.currentSession}");
      if (!SupabaseConfig.isConfigured) {
        context.go('/onboarding');
        return;
      }
      final bool signedIn = SupabaseService.client.auth.currentSession != null;
      final selectedId = await ProfileSessionService.getSelectedProfile();
      if (!mounted) return;

      if (!signedIn) {
        context.go('/auth');
        return;
      }

      if (selectedId == null) {
        context.go('/profiles');
        return;
      }
      final member = await ref
          .read(familyRepositoryProvider)
          .getFamilyMemberById(selectedId);

      if (member == null) {
        await ProfileSessionService.clearSelectedProfile();

        if (mounted) {
          context.go('/profiles');
        }
        return;
      }

      ref.read(selectedFamilyMemberProvider.notifier).state = member;

      if (mounted) {
        context.go('/app');
      }
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.checkroom_rounded, size: 64),
          SizedBox(height: 16),
          Text('Digital Wardrobe'),
        ],
      ),
    ),
  );
}
