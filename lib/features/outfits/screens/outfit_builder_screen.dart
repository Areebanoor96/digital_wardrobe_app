import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/outfit.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/garment_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OutfitBuilderScreen extends ConsumerStatefulWidget {
  const OutfitBuilderScreen({super.key, this.outfit});
  final Outfit? outfit;

  @override
  ConsumerState<OutfitBuilderScreen> createState() =>
      _OutfitBuilderScreenState();
}

class _OutfitBuilderScreenState extends ConsumerState<OutfitBuilderScreen> {
  late final List<String> _selectedIds = List<String>.from(
    widget.outfit?.garmentIds ?? const <String>[],
  );
  late final TextEditingController _name = TextEditingController(
    text: widget.outfit?.name,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
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
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_selectedIds.length} selected · select 2–6 pieces',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            if (_selectedIds.isNotEmpty)
              SizedBox(
                height: 62,
                child: ReorderableListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _selectedIds.length,
                  onReorderItem: (int oldIndex, int newIndex) => setState(() {
                    final String garmentId = _selectedIds.removeAt(oldIndex);
                    _selectedIds.insert(newIndex, garmentId);
                  }),
                  itemBuilder: (BuildContext context, int index) {
                    final Garment? garment = items
                        .where((Garment item) => item.id == _selectedIds[index])
                        .firstOrNull;
                    return Padding(
                      key: ValueKey<String>(_selectedIds[index]),
                      padding: const EdgeInsets.only(right: 8),
                      child: InputChip(
                        label: Text(garment?.name ?? 'Garment'),
                        onDeleted: () =>
                            setState(() => _selectedIds.removeAt(index)),
                      ),
                    );
                  },
                ),
              ),
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
