import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/core/widgets/back_arrow_button.dart';
import 'package:digital_wardrobe_app/data/models/garment_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GarmentLocationsScreen extends ConsumerWidget {
  const GarmentLocationsScreen({super.key});

  static const List<String> suggestions = <String>[
    'Almirah',
    'Storage Bag',
    'Suitcase',
    'Drawer',
    'Shelf',
    'Other',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<GarmentLocation>> locations = ref.watch(
      garmentLocationsProvider,
    );
    final AsyncValue<void> mutationState = ref.watch(
      garmentLocationControllerProvider,
    );

    return Scaffold(
      appBar: AppBar(
        leading: const BackArrowButton(),
        title: const Text('Garment Locations'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: mutationState.isLoading
            ? null
            : () => _showLocationDialog(context, ref),
        icon: mutationState.isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add),
        label: const Text('Add Location'),
      ),
      body: locations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: FilledButton.icon(
            onPressed: () => ref.invalidate(garmentLocationsProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry Locations'),
          ),
        ),
        data: (List<GarmentLocation> items) {
          if (items.isEmpty) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: <Widget>[
                Text(
                  'Suggestions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: suggestions
                      .map(
                        (String name) => ActionChip(
                          avatar: const Icon(Icons.add),
                          label: Text(name),
                          onPressed: mutationState.isLoading
                              ? null
                              : () => _create(context, ref, name),
                        ),
                      )
                      .toList(),
                ),
              ],
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(garmentLocationsProvider);
              await ref.read(garmentLocationsProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (BuildContext context, int index) {
                final GarmentLocation location = items[index];

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: Text(location.name),
                  trailing: Wrap(
                    spacing: 4,
                    children: <Widget>[
                      IconButton(
                        onPressed: mutationState.isLoading
                            ? null
                            : () => _showLocationDialog(
                                  context,
                                  ref,
                                  location: location,
                                ),
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Rename Location',
                      ),
                      IconButton(
                        onPressed: mutationState.isLoading
                            ? null
                            : () => _delete(context, ref, location),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete Location',
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _showLocationDialog(
    BuildContext context,
    WidgetRef ref, {
    GarmentLocation? location,
  }) async {
    final String? name = await showDialog<String>(
      context: context,
      builder: (_) => _LocationDialog(location: location),
    );

    if (name == null || name.trim().isEmpty || !context.mounted) {
      return;
    }

    if (location == null) {
      await _create(context, ref, name);
    } else {
      await ref
          .read(garmentLocationControllerProvider.notifier)
          .rename(locationId: location.id, name: name);
      if (!context.mounted) {
        return;
      }
      _showMutationSnackBar(context, ref, success: 'Location renamed.');
    }
  }

  Future<void> _create(
    BuildContext context,
    WidgetRef ref,
    String name,
  ) async {
    await ref
        .read(garmentLocationControllerProvider.notifier)
        .create(name: name);
    if (!context.mounted) {
      return;
    }
    _showMutationSnackBar(context, ref, success: 'Location created.');
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    GarmentLocation location,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text('Delete ${location.name}?'),
        content: const Text(
          'Locations can only be deleted when no garments use them.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await ref
        .read(garmentLocationControllerProvider.notifier)
        .delete(locationId: location.id);
    if (!context.mounted) {
      return;
    }
    _showMutationSnackBar(context, ref, success: 'Location deleted.');
  }

  void _showMutationSnackBar(
    BuildContext context,
    WidgetRef ref, {
    required String success,
  }) {
    if (!context.mounted) {
      return;
    }

    final AsyncValue<void> state = ref.read(garmentLocationControllerProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          state.hasError
              ? state.error?.toString() ?? 'Location could not be saved.'
              : success,
        ),
      ),
    );
  }
}

class _LocationDialog extends StatefulWidget {
  const _LocationDialog({this.location});

  final GarmentLocation? location;

  @override
  State<_LocationDialog> createState() => _LocationDialogState();
}

class _LocationDialogState extends State<_LocationDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.location?.name ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String value) => Navigator.pop(context, value);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.location == null ? 'Add Location' : 'Rename Location'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Location Name'),
        onSubmitted: _submit,
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => _submit(_controller.text),
          child: Text(widget.location == null ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}
