import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/core/theme/app_spacing.dart';
import 'package:digital_wardrobe_app/core/widgets/app_empty_state.dart';
import 'package:digital_wardrobe_app/core/widgets/app_loading_state.dart';
import 'package:digital_wardrobe_app/core/widgets/back_arrow_button.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/wardrobe/providers/favorites_provider.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/garment_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Garment>> garmentsAsync = ref.watch(garmentsProvider);
    final AsyncValue<Set<String>> favoritesAsync = ref.watch(favoritesProvider);
    final List<Garment> favoriteGarments = ref.watch(favoriteGarmentsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const BackArrowButton(),
        title: const Text('My Favorites'),
        centerTitle: true,
      ),
      body: garmentsAsync.isLoading || favoritesAsync.isLoading
          ? const AppLoadingState(
        showIcon: false,
        label: 'Loading your favorites',
      )
          : favoriteGarments.isEmpty
          ? const AppEmptyState(
        icon: Icons.favorite_border_rounded,
        title: 'No favorites yet',
        message: 'Tap the heart on items you love to save them here.',
      )
          : GridView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          100.0,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.lg,
          childAspectRatio: .58,
        ),
        itemCount: favoriteGarments.length,
        itemBuilder: (BuildContext context, int index) {
          final Garment garment = favoriteGarments[index];
          return GarmentCard(
            garment: garment,
            isFavorite: true,
            onToggleFavorite: () {
              ref
                  .read(favoritesProvider.notifier)
                  .toggleFavorite(garment.id);
            },
            onTap: () => context.push('/garments/${garment.id}'),
          );
        },
      ),
    );
  }
}