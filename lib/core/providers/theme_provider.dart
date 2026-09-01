import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Active application theme mode (light/dark).
///
/// Defaults to light and is seeded from the persisted preference in `main()`
/// via [StateProvider.overrideWith] so dark mode survives restarts while
/// defaulting to the existing light theme.
final StateProvider<ThemeMode> themeModeProvider = StateProvider<ThemeMode>(
  (Ref ref) => ThemeMode.light,
);