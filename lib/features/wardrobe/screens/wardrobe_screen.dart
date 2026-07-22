import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/garment_card.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/wardrobe_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  String _query = '';
  GarmentCategory? _category;

  @override
  Widget build(BuildContext context) {
    final garments = ref.watch(garmentsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Wardrobe')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/garments/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
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
          final List<Garment> filtered = allGarments
              .where(
                (Garment garment) =>
                    (_category == null || garment.category == _category) &&
                    ('${garment.name} ${garment.brand ?? ''} ${garment.colorName ?? ''}')
                        .toLowerCase()
                        .contains(_query.toLowerCase()),
              )
              .toList();
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(garmentsProvider),
            child: CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: TextField(
                      onChanged: (String value) =>
                          setState(() => _query = value),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search your closet',
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 46,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: <Widget>[
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _category == null,
                          onSelected: (_) => setState(() => _category = null),
                        ),
                        ...GarmentCategory.values.map(
                          (GarmentCategory category) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: ChoiceChip(
                              label: Text(category.label),
                              selected: _category == category,
                              onSelected: (_) =>
                                  setState(() => _category = category),
                            ),
                          ),
                        ),
                      ],
                    ),
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
                          : 'Try adjusting your search or category filter.',
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
