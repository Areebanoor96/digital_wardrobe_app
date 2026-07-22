import 'package:digital_wardrobe_app/core/router/app_router.dart';
import 'package:digital_wardrobe_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class DigitalWardrobeApp extends StatelessWidget {
  const DigitalWardrobeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Digital Wardrobe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
