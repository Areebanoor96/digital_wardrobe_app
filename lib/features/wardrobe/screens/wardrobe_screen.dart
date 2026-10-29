import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/core/theme/app_spacing.dart';
import 'package:digital_wardrobe_app/core/widgets/app_empty_state.dart';
import 'package:digital_wardrobe_app/core/widgets/app_loading_state.dart';
import 'package:digital_wardrobe_app/core/widgets/back_arrow_button.dart';
import 'package:digital_wardrobe_app/data/models/alert.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/garment_location.dart';
import 'package:digital_wardrobe_app/features/alerts/providers/alerts_provider.dart';
import 'package:digital_wardrobe_app/features/profile/widgets/family_member_avatar.dart';
import 'package:digital_wardrobe_app/features/wardrobe/models/wardrobe_filters.dart';
import 'package:digital_wardrobe_app/features/wardrobe/providers/favorites_provider.dart';
import 'package:digital_wardrobe_app/features/wardrobe/providers/wardrobe_filter_provider.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/active_filter_chips.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/garment_card.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/wardrobe_category_navigation.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/wardrobe_filter_sheet.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/wardrobe_filter_toolbar.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/wardrobe_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({
    super.key,
    this.canNavigateBack = false,
    this.onNavigateBack,
  });

  final bool canNavigateBack;
  final VoidCallback? onNavigateBack;

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final String existingQuery = ref.read(wardrobeFilterProvider).searchQuery;
    _searchController = TextEditingController(text: existingQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final FamilyMember? selectedMember = ref.watch(selectedFamilyMemberProvider);
    final Set<String> favoriteIds = ref.watch(favoritesProvider).valueOrNull ?? const <String>{};
    final AsyncValue<List<Garment>> garments = ref.watch(garmentsProvider);
    final AsyncValue<List<Alert>> alerts = ref.watch(alertsProvider);

    final int unreadCount = alerts.valueOrNull?.where((Alert alert) => !alert.isRead).length ?? 0;
    final WardrobeFilters filters = ref.watch(wardrobeFilterProvider);
    final List<Garment> filtered = ref.watch(filteredGarmentsProvider);

    final Map<String, String> locationNames = <String, String>{
      for (final GarmentLocation location in ref.watch(garmentLocationsProvider).valueOrNull ?? const <GarmentLocation>[])
        location.id: location.name,
    };

    return Scaffold(
      appBar: AppBar(
        leading: widget.canNavigateBack
            ? BackArrowButton(onPressed: widget.onNavigateBack)
            : null,
        title: const Text(
          'My Wardrobe',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 24,
            letterSpacing: -0.4,
            color: Color(0xFF1C1C1E),
          ),
        ),
        titleSpacing: AppSpacing.xl,
        actions: <Widget>[
          // Profile Avatar at top-right corner matching Screenshot 1
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xl),
            child: Center(
              child: GestureDetector(
                onTap: () => context.push('/profiles'),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE8D7CA),
                      width: 2,
                    ),
                  ),
                  child: FamilyMemberAvatar(
                    name: selectedMember?.name ?? 'User',
                    avatarUrl: selectedMember?.avatarUrl,
                    radius: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: garments.maybeWhen(
        data: (List<Garment> allGarments) {
          if (allGarments.isEmpty) return null;

          return FloatingActionButton(
            onPressed: () => context.push('/garments/new'),
            tooltip: 'Add item',
            backgroundColor: const Color(0xFF4A5D4E),
            foregroundColor: Colors.white,
            elevation: 2,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, size: 28),
          );
        },
        orElse: () => null,
      ),
      body: garments.when(
        loading: () => const Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            top: AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppLoadingState(showIcon: false, label: 'Loading your closet'),
            ],
          ),
        ),
        error: (_, __) => AppErrorState(
          title: 'We could not load your wardrobe',
          message: 'Check your connection and try again.',
          onAction: () => ref.invalidate(garmentsProvider),
        ),
        data: (List<Garment> allGarments) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(garmentsProvider),
            child: CustomScrollView(
              slivers: <Widget>[
                // Search & Action Row
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.xs,
                      AppSpacing.xl,
                      AppSpacing.md,
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: WardrobeSearchBar(
                            controller: _searchController,
                            searchQuery: filters.searchQuery,
                            hintText: 'Search Wardrobe',
                            onChanged: ref
                                .read(wardrobeFilterProvider.notifier)
                                .setSearchQuery,
                            onClear: () {
                              _searchController.clear();
                              ref
                                  .read(wardrobeFilterProvider.notifier)
                                  .setSearchQuery('');
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // Notifications bell (with red unread dot badge)
                        IconButton(
                          onPressed: () => context.push('/alerts'),
                          tooltip: 'Notifications',
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          icon: Badge(
                            isLabelVisible: unreadCount > 0,
                            backgroundColor: const Color(0xFFE05C5C),
                            smallSize: 8,
                            label: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              size: 26,
                              color: Color(0xFF1C1C1E),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        // Closet Vault bag icon
                        IconButton(
                          onPressed: () => context.push('/garments/archived'),
                          tooltip: 'Closet Vault',
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.shopping_bag_outlined,
                            size: 26,
                            color: Color(0xFF1C1C1E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Category pills
                SliverToBoxAdapter(
                  child: WardrobeCategoryNavigation(
                    selectedCategory: filters.category,
                    onSelected: ref
                        .read(wardrobeFilterProvider.notifier)
                        .setCategory,
                  ),
                ),

                // Sort by / Filter by buttons
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.sm,
                      AppSpacing.xl,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        WardrobeFilterToolbar(
                          filters: filters,
                          onOpenFilters: () {
                            showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              builder: (BuildContext context) {
                                return WardrobeFilterSheet(
                                  garments: allGarments,
                                );
                              },
                            );
                          },
                          onSortSelected: ref
                              .read(wardrobeFilterProvider.notifier)
                              .setSortOption,
                        ),
                        if (filters.activeFilterCount > 0) ...<Widget>[
                          const SizedBox(height: AppSpacing.sm),
                          ActiveFilterChips(
                            filters: filters,
                            locationNames: locationNames,
                            onColorRemoved: () => ref
                                .read(wardrobeFilterProvider.notifier)
                                .setColor(null),
                            onBrandRemoved: () => ref
                                .read(wardrobeFilterProvider.notifier)
                                .setBrand(null),
                            onSizeRemoved: () => ref
                                .read(wardrobeFilterProvider.notifier)
                                .setSize(null),
                            onOccasionRemoved: () => ref
                                .read(wardrobeFilterProvider.notifier)
                                .setOccasion(null),
                            onSeasonRemoved: () => ref
                                .read(wardrobeFilterProvider.notifier)
                                .setSeason(null),
                            onMoodRemoved: () => ref
                                .read(wardrobeFilterProvider.notifier)
                                .setMood(null),
                            onLaundryStatusRemoved: () => ref
                                .read(wardrobeFilterProvider.notifier)
                                .setLaundryStatus(null),
                            onAvailabilityStatusRemoved: () => ref
                                .read(wardrobeFilterProvider.notifier)
                                .setAvailabilityStatus(null),
                            onLocationRemoved: () => ref
                                .read(wardrobeFilterProvider.notifier)
                                .setLocation(),
                            onStitchingStatusRemoved: () => ref
                                .read(wardrobeFilterProvider.notifier)
                                .setStitchingStatus(null),
                            onIroningStatusRemoved: () => ref
                                .read(wardrobeFilterProvider.notifier)
                                .setIroningStatus(null),
                            onOuterwearSubcategoryRemoved: () => ref
                                .read(wardrobeFilterProvider.notifier)
                                .setOuterwearSubcategory(null),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                      icon: Icons.checkroom_outlined,
                      title: allGarments.isEmpty
                          ? 'Your wardrobe is empty'
                          : 'No matching garments',
                      message: allGarments.isEmpty
                          ? 'Add your first piece to start building your digital wardrobe.'
                          : 'Try changing your search, filters, or sorting options.',
                      actionLabel: allGarments.isEmpty
                          ? 'Add first garment'
                          : null,
                      onAction: allGarments.isEmpty
                          ? () => context.push('/garments/new')
                          : null,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.md,
                      AppSpacing.xl,
                      96,
                    ),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                          final Garment garment = filtered[index];
                          return GarmentCard(
                            garment: garment,
                            isFavorite: favoriteIds.contains(garment.id),
                            showMetadata: false,
                            onToggleFavorite: () => ref
                                .read(favoritesProvider.notifier)
                                .toggleFavorite(garment.id),
                            onTap: () =>
                                context.push('/garments/${garment.id}'),
                          );
                        },
                        childCount: filtered.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                        childAspectRatio: 0.88,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
