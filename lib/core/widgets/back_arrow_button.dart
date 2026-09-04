import 'package:flutter/material.dart';

import '../theme/app_radius.dart';

/// Standard back button for Digital Wardrobe.
///
/// Visually consistent with the app's navigation treatment. Keeps the
/// existing generic back-navigation behaviour (`Navigator.maybePop` by
/// default) — callers may override [onPressed] but must not change the
/// navigation/back-stack logic.
class BackArrowButton extends StatelessWidget {
  const BackArrowButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return IconButton(
      tooltip: 'Back',
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
      ),
      icon: const Icon(Icons.arrow_back),
    );
  }
}