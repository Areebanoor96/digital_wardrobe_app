import 'package:digital_wardrobe_app/core/config/supabase_config.dart';
import 'package:digital_wardrobe_app/core/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!SupabaseConfig.isConfigured) {
        context.go('/onboarding');
        return;
      }
      final bool signedIn = SupabaseService.client.auth.currentSession != null;
      if (mounted) context.go(signedIn ? '/app' : '/auth');
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
