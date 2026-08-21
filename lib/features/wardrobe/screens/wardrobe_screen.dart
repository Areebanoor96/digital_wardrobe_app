import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/active_filter_chips.dart';
import 'package:digital_wardrobe_app/features/wardrobe/models/wardrobe_filters.dart';
import 'package:digital_wardrobe_app/features/wardrobe/providers/wardrobe_filter_provider.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/garment_card.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/wardrobe_feedback.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/wardrobe_filter_sheet.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/features/profile/utils/select_family_member.dart';
import 'package:digital_wardrobe_app/features/profile/widgets/family_member_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/wardrobe_search_bar.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/wardrobe_category_chips.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/wardrobe_filter_toolbar.dart';
import 'package:go_router/go_router.dart';

class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

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

    if (!mounted) {
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
                    subtitle: Text(member.relationship.label),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wardrobe'),
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
        loading: () => const GarmentGridShimmer(),
        error: (_, _) => WardrobeEmptyState(
          title: 'We could not load your wardrobe',
          message: 'Check your connection and try again.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(garmentsProvider),
        ),
        data: (List<Garment> allGarments) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(garmentsProvider),
            child: CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
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

                SliverToBoxAdapter(
                  child: WardrobeCategoryChips(
                    selectedCategory: filters.category,
                    onSelected: ref
                        .read(wardrobeFilterProvider.notifier)
                        .setCategory,
                  ),
                ),

                SliverToBoxAdapter(
                  child: WardrobeFilterToolbar(
                    filters: filters,
                    filteredCount: filtered.length,
                    totalCount: allGarments.length,
                    onOpenFilters: () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        builder: (BuildContext context) {
                          return WardrobeFilterSheet(garments: allGarments);
                        },
                      );
                    },
                    onSortSelected: ref
                        .read(wardrobeFilterProvider.notifier)
                        .setSortOption,
                  ),
                ),
                if (filters.activeFilterCount > 0)
                  SliverToBoxAdapter(
                    child: ActiveFilterChips(
                      filters: filters,
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
                    ),
                  ),

                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: WardrobeEmptyState(
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
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
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
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: .62,
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
