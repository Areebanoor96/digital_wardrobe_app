import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/garment_image.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/garment_status_widgets.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/wear_history_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class GarmentDetailScreen extends ConsumerWidget {
  const GarmentDetailScreen({
    super.key,
    required this.garmentId,
  });

  final String garmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<void> wearState = ref.watch(
      wearLogControllerProvider,
    );

    final history = ref.watch(
      garmentWearHistoryProvider(garmentId),
    );

    return ref.watch(garmentProvider(garmentId)).when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, _) => Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('This garment could not be loaded.'),
        ),
      ),
      data: (Garment garment) => Scaffold(
        appBar: AppBar(
          actions: <Widget>[
            IconButton(
              onPressed: () => context.push(
                '/garments/$garmentId/edit',
                extra: garment,
              ),
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit garment',
            ),
            IconButton(
              onPressed: () => _archive(
                context,
                ref,
                garment,
              ),
              icon: const Icon(Icons.archive_outlined),
              tooltip: 'Archive garment',
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: <Widget>[
            AspectRatio(
              aspectRatio: 1,
              child: GarmentImage(
                imageUrl: garment.coverImageUrl,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    garment.name,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <String?>[
                      garment.category.label,
                      garment.colorName,
                      garment.size,
                    ]
                        .whereType<String>()
                        .map(
                          (String text) => Chip(
                        label: Text(text),
                      ),
                    )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: wearState.isLoading
                        ? null
                        : () => _markAsWorn(
                      context,
                      ref,
                    ),
                    icon: wearState.isLoading
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      wearState.isLoading
                          ? 'Recording...'
                          : 'Mark as Worn',
                    ),
                  ),
                  const SizedBox(height: 28),
                  _Section(
                    title: 'Wear statistics',
                    child: WearStatsRow(garment: garment),
                  ),
                  const SizedBox(height: 24),
                  _Section(
                    title: 'Laundry status',
                    child: LaundryStatusPill(
                      status: garment.laundryStatus,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _Section(
                    title: 'Wear history',
                    child: history.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (_, _) => TextButton.icon(
                        onPressed: () => ref.invalidate(
                          garmentWearHistoryProvider(garmentId),
                        ),
                        icon: const Icon(Icons.refresh),
                        label: const Text(
                          'Retry loading wear history',
                        ),
                      ),
                      data: (history) => WearHistoryList(
                        history: history,
                      ),
                    ),
                  ),
                  if (garment.price != null ||
                      garment.purchaseDate != null ||
                      garment.brand != null ||
                      garment.purchaseStore != null) ...<Widget>[
                    const SizedBox(height: 24),
                    _Section(
                      title: 'Purchase information',
                      child: _DetailsList(
                        values: <String, String?>{
                          'Brand': garment.brand,
                          'Store and location': garment.purchaseStore,
                          'Price': garment.price == null
                              ? null
                              : '${garment.currency} '
                              '${garment.price!.toStringAsFixed(0)}',
                          'Purchased': garment.purchaseDate == null
                              ? null
                              : _formatDate(garment.purchaseDate!),
                        },
                      ),
                    ),
                  ],
                  if (garment.fabric != null ||
                      garment.washInstructions != null) ...<Widget>[
                    const SizedBox(height: 24),
                    _Section(
                      title: 'Care information',
                      child: _DetailsList(
                        values: <String, String?>{
                          'Fabric': garment.fabric,
                          'Instructions': garment.washInstructions,
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAsWorn(
      BuildContext context,
      WidgetRef ref,
      ) async {
    final _WearEntryData? wearEntry =
    await showDialog<_WearEntryData>(
      context: context,
      builder: (BuildContext dialogContext) {
        return const _WearEntryDialog();
      },
    );

    if (wearEntry == null || !context.mounted) {
      return;
    }

    await ref.read(wearLogControllerProvider.notifier).markAsWorn(
      garmentId,
      eventName: wearEntry.eventName,
      notes: wearEntry.notes,
      laundryStatusAfter: wearEntry.laundryStatusAfter,
    );

    if (!context.mounted) {
      return;
    }

    final AsyncValue<void> state = ref.read(
      wearLogControllerProvider,
    );

    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not record this wear.'),
        ),
      );
      return;
    }

    ref.invalidate(garmentProvider(garmentId));
    ref.invalidate(garmentsProvider);
    ref.invalidate(garmentWearHistoryProvider(garmentId));
    ref.invalidate(recentWearActivityProvider);
    ref.invalidate(selectedDayWearHistoryProvider);
    ref.invalidate(analyticsSummaryProvider);
    ref.invalidate(costPerWearProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Wear recorded successfully.'),
      ),
    );
  }

  Future<void> _archive(
      BuildContext context,
      WidgetRef ref,
      Garment garment,
      ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Archive this garment?'),
        content: const Text(
          'It will be removed from your wardrobe but kept safely '
              'in your account.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              false,
            ),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              true,
            ),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final FamilyMember? selectedMember = ref.read(
      selectedFamilyMemberProvider,
    );

    if (selectedMember == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a profile first.'),
          ),
        );
      }
      return;
    }

    if (garment.memberId != selectedMember.id) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This garment does not belong to the selected profile.',
            ),
          ),
        );
      }
      return;
    }

    try {
      await ref.read(garmentRepositoryProvider).archiveGarment(
        garmentId: garmentId,
        memberId: selectedMember.id,
      );

      ref.invalidate(garmentsProvider);
      ref.invalidate(garmentProvider(garmentId));

      if (context.mounted) {
        context.pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Garment archived.'),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not archive this garment.'),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _WearEntryData {
  const _WearEntryData({
    required this.eventName,
    required this.laundryStatusAfter,
    this.notes,
  });

  final String eventName;
  final String? notes;
  final LaundryStatus laundryStatusAfter;
}

class _WearEntryDialog extends StatefulWidget {
  const _WearEntryDialog();

  @override
  State<_WearEntryDialog> createState() => _WearEntryDialogState();
}

class _WearEntryDialogState extends State<_WearEntryDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _eventController =
  TextEditingController();

  final TextEditingController _notesController =
  TextEditingController();

  LaundryStatus _selectedLaundryStatus = LaundryStatus.dirty;

  @override
  void dispose() {
    _eventController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String notes = _notesController.text.trim();

    Navigator.pop(
      context,
      _WearEntryData(
        eventName: _eventController.text.trim(),
        notes: notes.isEmpty ? null : notes,
        laundryStatusAfter: _selectedLaundryStatus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mark as worn'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _eventController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Event *',
                  hintText: 'For example: University, Work or Wedding',
                  prefixIcon: Icon(Icons.event_outlined),
                ),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an event';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Optional notes about this wear',
                  prefixIcon: Icon(Icons.notes_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<LaundryStatus>(
                initialValue: _selectedLaundryStatus,
                decoration: const InputDecoration(
                  labelText: 'Laundry status after wearing',
                  prefixIcon: Icon(
                    Icons.local_laundry_service_outlined,
                  ),
                ),
                items: LaundryStatus.values
                    .map(
                      (LaundryStatus status) =>
                      DropdownMenuItem<LaundryStatus>(
                        value: status,
                        child: Text(
                          _laundryStatusLabel(status),
                        ),
                      ),
                )
                    .toList(),
                onChanged: (LaundryStatus? value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _selectedLaundryStatus = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.check),
          label: const Text('Record wear'),
        ),
      ],
    );
  }

  String _laundryStatusLabel(LaundryStatus status) {
    switch (status) {
      case LaundryStatus.clean:
        return 'Clean';
      case LaundryStatus.dirty:
        return 'Dirty';
      case LaundryStatus.washing:
        return 'Washing';
      case LaundryStatus.ironing:
        return 'Ironing';
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _DetailsList extends StatelessWidget {
  const _DetailsList({
    required this.values,
  });

  final Map<String, String?> values;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: values.entries
          .where(
            (MapEntry<String, String?> entry) =>
        entry.value != null &&
            entry.value!.trim().isNotEmpty,
      )
          .map(
            (MapEntry<String, String?> entry) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 104,
                child: Text(
                  entry.key,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Expanded(
                child: Text(entry.value!),
              ),
            ],
          ),
        ),
      )
          .toList(),
    );
  }
}