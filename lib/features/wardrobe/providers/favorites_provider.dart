import 'dart:async';
import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesNotifier extends AsyncNotifier<Set<String>> {
  String get _storageKey {
    final FamilyMember? member = ref.read(selectedFamilyMemberProvider);
    final String memberSuffix = member != null ? '_${member.id}' : '';
    return 'favorite_garment_ids$memberSuffix';
  }

  @override
  FutureOr<Set<String>> build() async {
    // Re-evaluates whenever user switches family profile
    ref.watch(selectedFamilyMemberProvider);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> stored = prefs.getStringList(_storageKey) ?? <String>[];
    return stored.toSet();
  }

  Future<void> toggleFavorite(String garmentId) async {
    final Set<String> current = state.valueOrNull ?? <String>{};
    final Set<String> updated = Set<String>.from(current);

    if (updated.contains(garmentId)) {
      updated.remove(garmentId);
    } else {
      updated.add(garmentId);
    }

    // 1. Optimistic update (UI updates with zero perceived lag)
    state = AsyncData<Set<String>>(updated);

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, updated.toList());
    } catch (_) {
      // 2. Revert back if disk write fails
      state = AsyncData<Set<String>>(current);
    }
  }

  bool isFavorite(String garmentId) {
    return state.valueOrNull?.contains(garmentId) ?? false;
  }
}

final AsyncNotifierProvider<FavoritesNotifier, Set<String>> favoritesProvider =
AsyncNotifierProvider<FavoritesNotifier, Set<String>>(
  FavoritesNotifier.new,
);

/// Derived provider exposing only active, non-archived favorite garments
final Provider<List<Garment>> favoriteGarmentsProvider =
Provider<List<Garment>>((Ref ref) {
  final List<Garment> allGarments =
      ref.watch(garmentsProvider).valueOrNull ?? const <Garment>[];
  final Set<String> favoriteIds =
      ref.watch(favoritesProvider).valueOrNull ?? const <String>{};

  return allGarments
      .where(
        (Garment garment) =>
    favoriteIds.contains(garment.id) && !garment.isArchived,
  )
      .toList();
});