import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/outfit.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/garment_card.dart';
import 'package:flutter/material.dart';
import 'package:digital_wardrobe_app/features/outfits/models/outfit_context.dart';
import 'package:digital_wardrobe_app/features/outfits/services/outfit_intelligence_engine.dart';
import 'package:digital_wardrobe_app/features/outfits/models/outfit_intelligence_recommendation.dart';
import 'package:digital_wardrobe_app/features/outfits/providers/outfit_intelligence_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OutfitBuilderScreen extends ConsumerStatefulWidget {
  const OutfitBuilderScreen({super.key, this.outfit});
  final Outfit? outfit;

  @override
  ConsumerState<OutfitBuilderScreen> createState() =>
      _OutfitBuilderScreenState(
      );
}

class _OutfitBuilderScreenState extends ConsumerState<OutfitBuilderScreen> {
  late final List<String> _selectedIds = List<String>.from(
    widget.outfit?.garmentIds ?? const <String>[],
  );
  late final TextEditingController _name = TextEditingController(
    text: widget.outfit?.name,
  );
  bool _smartBuild = false;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }
  Future<void> _showSwapOptions({
    required Garment currentGarment,
    required List<Garment> allGarments,
    required List<Garment> currentOutfit,
    required OutfitContext outfitContext,
  }) async {
    final OutfitIntelligenceEngine engine = ref.read(
      outfitIntelligenceEngineProvider,
    );

    final List<Garment> alternatives = engine.swapCandidates(
      currentGarment: currentGarment,
      allGarments: allGarments,
      currentOutfit: currentOutfit,
      context: outfitContext,
    );

    if (!mounted) {
      return;
    }

    if (alternatives.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No other ${currentGarment.category.label.toLowerCase()} available.',
          ),
        ),
      );
      return;
    }

    final Garment? replacement = await showModalBottomSheet<Garment>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Swap ${currentGarment.name}',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose another ${currentGarment.category.label.toLowerCase()}.',
                ),
                const SizedBox(height: 12),

                ...alternatives.map(
                      (Garment garment) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      child: Icon(Icons.swap_horiz),
                    ),
                    title: Text(garment.name),
                    subtitle: Text(garment.category.label),
                    onTap: () {
                      Navigator.pop(sheetContext, garment);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (replacement == null || !mounted) {
      return;
    }

    setState(() {
      final int index = _selectedIds.indexOf(currentGarment.id);

      if (index != -1) {
        _selectedIds[index] = replacement.id;
      }
    });
  }
  Future<void> _save(List<Garment> garments) async {
    if (_selectedIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose at least two garments.')),
      );
      return;
    }
    final String name = _name.text.trim().isEmpty
        ? 'Untitled outfit'
        : _name.text.trim();
    final Garment? first = garments
        .where((Garment garment) => garment.id == _selectedIds.first)
        .firstOrNull;
    final controller = ref.read(outfitMutationControllerProvider.notifier);
    if (widget.outfit == null) {
      await controller.create(
        name: name,
        garmentIds: _selectedIds,
        coverPhotoUrl: first?.photoPaths.isEmpty == false
            ? first!.photoPaths.first
            : null,
      );
    } else {
      await controller.updateOutfit(
        outfit: widget.outfit!,
        name: name,
        garmentIds: _selectedIds,
      );
    }
    if (!mounted) return;
    final AsyncValue<void> state = ref.read(outfitMutationControllerProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save this outfit.')),
      );
      return;
    }
    ref.invalidate(outfitsProvider);
    if (widget.outfit != null) {
      ref.invalidate(outfitProvider(widget.outfit!.id));
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final garments = ref.watch(garmentsProvider);
    final bool saving = ref.watch(outfitMutationControllerProvider).isLoading;
    final OutfitContext outfitContext = ref.watch(
      outfitContextProvider,
    );
    final OutfitIntelligenceRecommendation? recommendation =
    ref.watch(outfitRecommendationProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.outfit == null ? 'Build outfit' : 'Edit outfit'),
      ),
      body: garments.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Could not load your wardrobe.')),
        data: (List<Garment> items) => Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Outfit name'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SegmentedButton<bool>(
                segments: const <ButtonSegment<bool>>[
                  ButtonSegment<bool>(
                    value: false,
                    icon: Icon(Icons.touch_app_outlined),
                    label: Text('Manual'),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    icon: Icon(Icons.auto_awesome_outlined),
                    label: Text('Smart Build'),
                  ),
                ],
                selected: <bool>{_smartBuild},
                onSelectionChanged: (Set<bool> value) {
                  setState(() {
                    _smartBuild = value.first;
                  });
                },
              ),
            ),
            if (_smartBuild)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Build around a hero piece',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Choose one garment, then add occasion, season and mood.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (_smartBuild && recommendation != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    const Icon(Icons.auto_awesome_outlined),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Recommended Outfit',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                    ),
                                    Text(
                                      '${recommendation.score}% match',
                                      style: Theme.of(context).textTheme.titleSmall,
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                if (recommendation.garments.isEmpty)
                                  Text(
                                    'No suitable outfit could be created from the available garments.',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  )
                                else ...<Widget>[
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: recommendation.garments
                                        .map(
                                          (Garment garment) => Chip(
                                        avatar: garment.id ==
                                            outfitContext.heroGarment?.id
                                            ? const Icon(
                                          Icons.star_outline,
                                          size: 18,
                                        )
                                            : null,
                                        label: Text(garment.name),
                                      ),
                                    )
                                        .toList(),
                                  ),

                                  if (recommendation.reasons.isNotEmpty) ...<Widget>[
                                    const SizedBox(height: 16),
                                    Text(
                                      'Why this works',
                                      style: Theme.of(context).textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 8),

                                    ...recommendation.reasons.map(
                                          (String reason) => Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: <Widget>[
                                            const Icon(
                                              Icons.check_circle_outline,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(reason),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 16),

                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _selectedIds
                                            ..clear()
                                            ..addAll(
                                              recommendation.garments
                                                  .map(
                                                    (Garment garment) => garment.id,
                                              )
                                                  .take(6),
                                            );
                                        });

                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Recommended outfit added to your selection.',
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.check),
                                      label: const Text('Use this outfit'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: outfitContext.heroGarment?.id,
                      decoration: const InputDecoration(
                        labelText: 'Hero garment',
                      ),
                      items: items
                          .map(
                            (Garment garment) => DropdownMenuItem<String>(
                          value: garment.id,
                          child: Text(garment.name),
                        ),
                      )
                          .toList(),
                      onChanged: (String? garmentId) {
                        final Garment? selectedGarment = items
                            .where(
                              (Garment garment) => garment.id == garmentId,
                        )
                            .firstOrNull;

                        ref.read(outfitContextProvider.notifier).state =
                            outfitContext.copyWith(
                              heroGarment: selectedGarment,
                              clearHeroGarment: selectedGarment == null,
                            );
                      },
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue : outfitContext.occasion,
                      decoration: const InputDecoration(
                        labelText: 'Occasion',
                      ),
                      items: const <String>[
                        'casual',
                        'work',
                        'formal',
                        'party',
                        'wedding',
                        'college',
                        'sport',
                        'travel',
                        'home',
                        'sleep',
                        'ethnic',
                      ]
                          .map(
                            (String value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value[0].toUpperCase() + value.substring(1),
                          ),
                        ),
                      )
                          .toList(),
                      onChanged: (String? value) {
                        ref.read(outfitContextProvider.notifier).state =
                        value == null
                            ? outfitContext.copyWith(
                          clearOccasion: true,
                        )
                            : outfitContext.copyWith(
                          occasion: value,
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue:  outfitContext.season,
                      decoration: const InputDecoration(
                        labelText: 'Season',
                      ),
                      items: const <String>[
                        'summer',
                        'winter',
                        'spring',
                        'autumn',
                        'rainy',
                        'all_season',
                      ]
                          .map(
                            (String value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value.replaceAll('_', ' '),
                          ),
                        ),
                      )
                          .toList(),
                      onChanged: (String? value) {
                        ref.read(outfitContextProvider.notifier).state =
                        value == null
                            ? outfitContext.copyWith(
                          clearSeason: true,
                        )
                            : outfitContext.copyWith(
                          season: value,
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue:outfitContext.mood,
                      decoration: const InputDecoration(
                        labelText: 'Mood',
                      ),
                      items: const <String>[
                        'relaxed',
                        'professional',
                        'cozy',
                        'elegant',
                        'sporty',
                        'minimal',
                        'bold',
                        'party',
                      ]
                          .map(
                            (String value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value[0].toUpperCase() + value.substring(1),
                          ),
                        ),
                      )
                          .toList(),
                      onChanged: (String? value) {
                        ref.read(outfitContextProvider.notifier).state =
                        value == null
                            ? outfitContext.copyWith(
                          clearMood: true,
                        )
                            : outfitContext.copyWith(
                          mood: value,
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_selectedIds.length} selected · select 2–6 pieces',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            if (_selectedIds.isNotEmpty) ...<Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Your Outfit',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      '${_selectedIds.length} pieces',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: 110,
                child: ReorderableListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _selectedIds.length,
                  onReorderItem: (int oldIndex, int newIndex) {
                    setState(() {
                      final String garmentId = _selectedIds.removeAt(oldIndex);
                      _selectedIds.insert(newIndex, garmentId);
                    });
                  },
                  itemBuilder: (BuildContext context, int index) {
                    final Garment? garment = items
                        .where(
                          (Garment item) => item.id == _selectedIds[index],
                    )
                        .firstOrNull;

                    if (garment == null) {
                      return const SizedBox.shrink(
                        key: ValueKey<String>('missing-garment'),
                      );
                    }

                    final List<Garment> currentOutfit = _selectedIds
                        .map(
                          (String id) => items
                          .where(
                            (Garment item) => item.id == id,
                      )
                          .firstOrNull,
                    )
                        .whereType<Garment>()
                        .toList();

                    return Container(
                      key: ValueKey<String>(garment.id),
                      width: 190,
                      margin: const EdgeInsets.only(right: 10),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                garment.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                garment.category.label,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const Spacer(),
                              Row(
                                children: <Widget>[
                                  TextButton.icon(
                                    onPressed: !_smartBuild
                                        ? null
                                        : () => _showSwapOptions(
                                      currentGarment: garment,
                                      allGarments: items,
                                      currentOutfit: currentOutfit,
                                      outfitContext: outfitContext,
                                    ),
                                    icon: const Icon(
                                      Icons.swap_horiz,
                                      size: 18,
                                    ),
                                    label: const Text('Swap'),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedIds.remove(garment.id);
                                      });
                                    },
                                    icon: const Icon(Icons.close),
                                    tooltip: 'Remove',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: .62,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final Garment garment = items[index];
                  final bool selected = _selectedIds.contains(garment.id);
                  return Stack(
                    children: <Widget>[
                      GarmentCard(
                        garment: garment,
                        onTap: () => setState(() {
                          if (selected) {
                            _selectedIds.remove(garment.id);
                          } else if (_selectedIds.length < 6) {
                            _selectedIds.add(garment.id);
                          }
                        }),
                      ),
                      if (selected)
                        const Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            radius: 14,
                            child: Icon(Icons.check, size: 18),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: saving ? null : () => _save(items),
                child: Text(saving ? 'Saving...' : 'Save outfit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
