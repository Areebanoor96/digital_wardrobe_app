import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/core/theme/app_dimensions.dart';
import 'package:digital_wardrobe_app/core/theme/app_spacing.dart';
import 'package:digital_wardrobe_app/core/widgets/app_empty_state.dart';
import 'package:digital_wardrobe_app/core/widgets/app_loading_state.dart';
import 'package:digital_wardrobe_app/core/widgets/back_arrow_button.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/garment_location.dart';
import 'package:digital_wardrobe_app/features/profile/utils/select_family_member.dart';
import 'package:digital_wardrobe_app/features/profile/widgets/family_member_avatar.dart';
import 'package:digital_wardrobe_app/features/wardrobe/models/wardrobe_filters.dart';
import 'package:digital_wardrobe_app/features/wardrobe/providers/wardrobe_filter_provider.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/active_filter_chips.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/garment_card.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/wardrobe_category_navigation.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/wardrobe_filter_sheet.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/wardrobe_filter_toolbar.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/wardrobe_header.dart';
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

  Future<void> _showProfileSwitcher(
    BuildContext context,
    FamilyMember selectedMember,
  ) async {
    final List<FamilyMember> members = await ref.read(
      familyMembersProvider.future,
    );
    Map<String, int> pieceCounts = const <String, int>{};
    try {
      pieceCounts = await ref.read(familyMemberPieceCountsProvider.future);
    } catch (_) {
      pieceCounts = const <String, int>{};
    }

    if (!context.mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Switch wardrobe',
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),

                for (final FamilyMember member in members)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: FamilyMemberAvatar(
                      name: member.name,
                      avatarUrl: member.avatarUrl,
                      radius: 22,
                    ),
                    title: Text(member.name),
                    subtitle: Text(
                      '${member.relationship.label} · '
                      '${pieceCounts[member.id] ?? 0} Pieces',
                    ),
                    trailing: member.id == selectedMember.id
                        ? const Icon(Icons.check_circle)
                        : null,
                    onTap: member.id == selectedMember.id
                        ? null
                        : () async {
                            Navigator.of(sheetContext).pop();

                            final bool selected = await selectFamilyMember(
                              context: context,
                              ref: ref,
                              member: member,
                            );

                            if (!mounted || !selected) {
                              return;
                            }

                            ref.invalidate(familyMembersProvider);
                          },
                  ),

                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.people_outline),
                  title: const Text('View all profiles'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.push('/profiles');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final FamilyMember? selectedMember = ref.watch(
      selectedFamilyMemberProvider,
    );
    final AsyncValue<List<Garment>> garments = ref.watch(garmentsProvider);

    final WardrobeFilters filters = ref.watch(wardrobeFilterProvider);

    final List<Garment> filtered = ref.watch(filteredGarmentsProvider);

    final Map<String, String> locationNames = <String, String>{
      for (final GarmentLocation location
          in ref.watch(garmentLocationsProvider).valueOrNull ??
              const <GarmentLocation>[])
        location.id: location.name,
    };

    return Scaffold(
      appBar: AppBar(
        leading: widget.canNavigateBack
            ? BackArrowButton(onPressed: widget.onNavigateBack)
            : null,
        actions: <Widget>[
          if (selectedMember != null)
            IconButton(
              onPressed: () => _showProfileSwitcher(context, selectedMember),
              tooltip: 'Switch profile',
              icon: FamilyMemberAvatar(
                name: selectedMember.name,
                avatarUrl: selectedMember.avatarUrl,
                radius: 17,
              ),
            ),
          IconButton(
            onPressed: () => context.push('/garments/archived'),
            icon: const Icon(Icons.archive_outlined),
            tooltip: 'Closet Vault',
          ),
        ],
      ),
      floatingActionButton: garments.maybeWhen(
        data: (List<Garment> allGarments) {
          if (allGarments.isEmpty) {
            return null;
          }

          return FloatingActionButton.extended(
            onPressed: () => context.push('/garments/new'),
            icon: const Icon(Icons.add),
            label: const Text('Add item'),
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
              WardrobeHeader(title: 'My Wardrobe', pieceCount: 0),
              SizedBox(height: AppSpacing.hero),
              AppLoadingState(
                showIcon: false,
                label: 'Loading your closet',
              ),
            ],
          ),
        ),
        error: (_, _) => AppErrorState(
          title: 'We could not load your wardrobe',
          message: 'Check your connection and try again.',
          onAction: () => ref.invalidate(garmentsProvider),
        ),
        data: (List<Garment> allGarments) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(garmentsProvider),
            child: CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Column(
                    children: <Widget>[
                      WardrobeHeader(
                        title: 'My Wardrobe',
                        pieceCount: allGarments.length,
                        trailing: selectedMember == null
                            ? null
                            : FamilyMemberAvatar(
                                name: selectedMember.name,
                                avatarUrl: selectedMember.avatarUrl,
                                radius: AppDimensions.avatarSm / 2,
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          0,
                          AppSpacing.xl,
                          AppSpacing.md,
                        ),
                        child: WardrobeSearchBar(
                          controller: _searchController,
                          searchQuery: filters.searchQuery,
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
                    ],
                  ),
                ),

                SliverToBoxAdapter(
                  child: WardrobeCategoryNavigation(
                    selectedCategory: filters.category,
                    onSelected: ref
                        .read(wardrobeFilterProvider.notifier)
                        .setCategory,
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.xl,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        WardrobeFilterToolbar(
                          filters: filters,
                          filteredCount: filtered.length,
                          totalCount: allGarments.length,
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
                          ? 'Add your first piece to start building your '
                                'digital wardrobe.'
                          : 'Try changing your search, filters, or sorting '
                                'options.',
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
                        (BuildContext context, int index) => GarmentCard(
                          garment: filtered[index],
                          onTap: () =>
                              context.push('/garments/${filtered[index].id}'),
                        ),
                        childCount: filtered.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: AppSpacing.md,
                            mainAxisSpacing: AppSpacing.lg,
                            childAspectRatio: .58,
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