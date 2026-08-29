import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/core/widgets/back_arrow_button.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/lending_record.dart';
import 'package:digital_wardrobe_app/data/models/wear_log.dart';
import 'package:digital_wardrobe_app/features/wardrobe/utils/garment_metadata_formatter.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/garment_photo_carousel.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/garment_status_widgets.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/wear_history_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class GarmentDetailScreen extends ConsumerWidget {
  const GarmentDetailScreen({super.key, required this.garmentId});

  final String garmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<void> wearState = ref.watch(wearLogControllerProvider);
    final AsyncValue<void> archiveState = ref.watch(
      garmentArchiveControllerProvider,
    );
    final AsyncValue<List<WearLog>> history = ref.watch(
      garmentWearHistoryProvider(garmentId),
    );
    final AsyncValue<LendingRecord?> activeLending = ref.watch(
      activeLendingRecordProvider(garmentId),
    );

    return ref
        .watch(garmentProvider(garmentId))
        .when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, _) => Scaffold(
            appBar: AppBar(leading: const BackArrowButton()),
            body: const Center(
              child: Text('This garment could not be loaded.'),
            ),
          ),
          data: (Garment garment) => Scaffold(
            appBar: AppBar(
              leading: const BackArrowButton(),
              actions: <Widget>[
                IconButton(
                  onPressed: () =>
                      context.push('/garments/$garmentId/edit', extra: garment),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit Item',
                ),
                if (!garment.isArchived)
                  IconButton(
                    onPressed: archiveState.isLoading
                        ? null
                        : () => _archive(context, ref, garment),
                    icon: archiveState.isLoading
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.archive_outlined),
                    tooltip: 'Move To Closet Vault',
                  )
                else
                  IconButton(
                    onPressed: archiveState.isLoading
                        ? null
                        : () => _restore(context, ref, garment),
                    icon: archiveState.isLoading
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.unarchive_outlined),
                    tooltip: 'Return To Wardrobe',
                  ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: <Widget>[
                GarmentPhotoCarousel(photoUrls: garment.photoUrls),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        garment.name,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      _GarmentDetailTags(garment: garment),
                      const SizedBox(height: 20),
                      if (garment.isArchived)
                        FilledButton.icon(
                          onPressed: archiveState.isLoading
                              ? null
                              : () => _restore(context, ref, garment),
                          icon: archiveState.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.unarchive_outlined),
                          label: Text(
                            archiveState.isLoading
                                ? 'Restoring...'
                                : 'Restore To Wardrobe',
                          ),
                        )
                      else
                        FilledButton.icon(
                          onPressed: wearState.isLoading
                              ? null
                              : () => _markAsWorn(context, ref),
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
                                : 'Mark As Worn',
                          ),
                        ),
                      const SizedBox(height: 28),
                      _Section(
                        title: 'Wear Statistics',
                        child: WearStatsRow(garment: garment),
                      ),
                      const SizedBox(height: 24),
                      _Section(
                        title: 'Item Status',
                        child: _DetailsList(
                          values: <String, String?>{
                            'Availability': garment.availabilityStatus.label,
                          },
                        ),
                      ),
                      if (garment.availabilityStatus ==
                              GarmentAvailabilityStatus.lent ||
                          garment.availabilityStatus ==
                              GarmentAvailabilityStatus.borrowed) ...<Widget>[
                        const SizedBox(height: 24),
                        _LendingSection(
                          garment: garment,
                          activeLending: activeLending,
                          onMarkReturned: () =>
                              _markReturned(context, ref, garment),
                          isReturning: ref
                              .watch(lendingControllerProvider)
                              .isLoading,
                          formatDate: _formatDate,
                        ),
                      ],
                      if (_hasCareInformation(garment)) ...<Widget>[
                        const SizedBox(height: 24),
                        _Section(
                          title: 'Care & Readiness',
                          child: _DetailsList(
                            values: <String, String?>{
                              'Wash Instructions': garment.washInstructions,
                            },
                          ),
                        ),
                      ],
                      if (_hasWardrobeInformation(garment)) ...<Widget>[
                        const SizedBox(height: 24),
                        _Section(
                          title: 'Wardrobe Information',
                          child: _DetailsList(
                            values: <String, String?>{
                              'Location': garment.locationName,
                              'Occasions':
                                  GarmentMetadataFormatter.detailListSummary(
                                    garment.occasions.map(_titleCase).toList(),
                                  ),
                            },
                          ),
                        ),
                      ],
                      if (_hasGarmentDetails(garment)) ...<Widget>[
                        const SizedBox(height: 24),
                        _Section(
                          title: 'Item Details',
                          child: _DetailsList(
                            values: <String, String?>{
                              if (_supportsSubcategory(garment.category))
                                _subcategoryLabel(
                                  garment.category,
                                ): _supportsSubcategory(garment.category)
                                    ? garment.subcategory
                                    : null,
                              if (_isClothing(garment.category))
                                ...<String, String?>{
                                  'Fabric': garment.fabric,
                                  'Fit': garment.fit,
                                  'Pattern': garment.pattern,
                                  'Fabric Weight': garment.fabricWeight,
                                },
                              if (_supportsSleeveLength(garment.category))
                                'Sleeve Length': garment.sleeveLength,
                              if (_supportsStitching(garment.category))
                                'Stitching': garment.stitchingStatus?.label,
                              if (garment.details?.trim().isNotEmpty ?? false)
                                'Details': garment.details,
                            },
                          ),
                        ),
                      ],
                      if (_hasPurchaseInformation(garment)) ...<Widget>[
                        const SizedBox(height: 24),
                        _Section(
                          title: 'Purchase Information',
                          child: _DetailsList(
                            values: <String, String?>{
                              'Brand': garment.brand,
                              'Store': garment.purchaseStore,
                              'Price': garment.price == null
                                  ? null
                                  : '${garment.currency} '
                                        '${garment.price!.toStringAsFixed(0)}',
                              'Purchase Date': garment.purchaseDate == null
                                  ? null
                                  : _formatDate(garment.purchaseDate!),
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      _Section(
                        title: 'Wear History',
                        child: history.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.all(12),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (_, _) => TextButton.icon(
                            onPressed: () => ref.invalidate(
                              garmentWearHistoryProvider(garmentId),
                            ),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry Loading Wear History'),
                          ),
                          data: (List<WearLog> history) => WearHistoryList(
                            history: history,
                            onDelete: (WearLog entry) =>
                                _deleteWear(context, ref, garment, entry),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
  }

  Future<void> _markAsWorn(BuildContext context, WidgetRef ref) async {
    final bool? recorded = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _WearEntryDialog(
          onSubmit: (_WearEntryData wearEntry) async {
            await ref
                .read(wearLogControllerProvider.notifier)
                .markAsWorn(
                  garmentId,
                  wornDate: wearEntry.wornDate,
                  eventName: wearEntry.eventName,
                  notes: wearEntry.notes,
                  laundryStatusAfter: wearEntry.laundryStatusAfter,
                );

            return !ref.read(wearLogControllerProvider).hasError;
          },
        );
      },
    );

    if (recorded != true || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wear Recorded Successfully.')),
    );
  }

  Future<void> _deleteWear(
    BuildContext context,
    WidgetRef ref,
    Garment garment,
    WearLog entry,
  ) async {
    await ref
        .read(wearLogControllerProvider.notifier)
        .deleteWear(garmentId: garment.id, wearLogId: entry.id);

    if (!context.mounted) {
      return;
    }

    final AsyncValue<void> state = ref.read(wearLogControllerProvider);

    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could Not Delete This Wear Record.')),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Wear Record Deleted.')));
  }

  Future<void> _archive(
    BuildContext context,
    WidgetRef ref,
    Garment garment,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Move To Closet Vault?'),
        content: const Text(
          'It will be removed from your wardrobe but kept safely '
          'in your Closet Vault.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Move To Closet Vault'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    if (ref.read(garmentArchiveControllerProvider).isLoading) {
      return;
    }

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final FamilyMember? selectedMember = ref.read(selectedFamilyMemberProvider);

    if (selectedMember == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please Select A Profile First.')),
      );
      return;
    }

    if (garment.memberId != selectedMember.id) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'This garment does not belong to the selected profile.',
          ),
        ),
      );
      return;
    }

    if (ref.read(garmentArchiveControllerProvider).isLoading) {
      return;
    }

    await ref
        .read(garmentArchiveControllerProvider.notifier)
        .archive(garmentId: garment.id);

    if (!context.mounted) {
      return;
    }

    final AsyncValue<void> state = ref.read(garmentArchiveControllerProvider);

    if (state.hasError) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could Not Move To Closet Vault.')),
      );
      return;
    }

    try {
      ref.invalidate(garmentsProvider);
      ref.invalidate(archivedGarmentsProvider);
      ref.invalidate(garmentProvider(garmentId));
    } catch (error) {
      debugPrint('Could not refresh garment providers after archive: $error');
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    messenger.showSnackBar(
      const SnackBar(content: Text('Moved To Closet Vault.')),
    );
  }

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    Garment garment,
  ) async {
    if (ref.read(garmentArchiveControllerProvider).isLoading) {
      return;
    }

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    await ref
        .read(garmentArchiveControllerProvider.notifier)
        .restore(garmentId: garment.id);

    if (!context.mounted) {
      return;
    }

    final AsyncValue<void> state = ref.read(garmentArchiveControllerProvider);

    if (state.hasError) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could Not Restore This Garment.')),
      );
      return;
    }

    try {
      ref.invalidate(garmentsProvider);
      ref.invalidate(archivedGarmentsProvider);
      ref.invalidate(garmentProvider(garmentId));
    } catch (error) {
      debugPrint('Could not refresh garment providers after restore: $error');
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    messenger.showSnackBar(
      const SnackBar(content: Text('Garment Restored To Wardrobe.')),
    );
  }

  Future<void> _markReturned(
    BuildContext context,
    WidgetRef ref,
    Garment garment,
  ) async {
    await ref
        .read(lendingControllerProvider.notifier)
        .markReturned(garmentId: garment.id);

    if (!context.mounted) {
      return;
    }

    final AsyncValue<void> state = ref.read(lendingControllerProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          state.hasError
              ? 'Could Not Mark This Garment Returned.'
              : 'Garment Marked Returned.',
        ),
      ),
    );
  }

  bool _hasWardrobeInformation(Garment garment) {
    return (garment.locationName?.trim().isNotEmpty ?? false) ||
        garment.occasions.any((String occasion) => occasion.trim().isNotEmpty);
  }

  bool _hasCareInformation(Garment garment) {
    return garment.washInstructions?.trim().isNotEmpty ?? false;
  }

  bool _hasGarmentDetails(Garment garment) {
    final bool clothingDetails =
        _isClothing(garment.category) &&
        ((garment.fabric?.trim().isNotEmpty ?? false) ||
            (garment.fit?.trim().isNotEmpty ?? false) ||
            (garment.pattern?.trim().isNotEmpty ?? false) ||
            (garment.fabricWeight?.trim().isNotEmpty ?? false));
    final bool subcategoryDetails =
        _supportsSubcategory(garment.category) &&
        (garment.subcategory?.trim().isNotEmpty ?? false);

    return subcategoryDetails ||
        clothingDetails ||
        (_supportsSleeveLength(garment.category) &&
            (garment.sleeveLength?.trim().isNotEmpty ?? false)) ||
        (_supportsStitching(garment.category) &&
            garment.stitchingStatus != null) ||
        (garment.details?.trim().isNotEmpty ?? false);
  }

  bool _hasPurchaseInformation(Garment garment) {
    return (garment.brand?.trim().isNotEmpty ?? false) ||
        (garment.purchaseStore?.trim().isNotEmpty ?? false) ||
        garment.price != null ||
        garment.purchaseDate != null;
  }

  bool _supportsSleeveLength(GarmentCategory category) {
    return category == GarmentCategory.top ||
        category == GarmentCategory.dress ||
        category == GarmentCategory.outerwear;
  }

  bool _isClothing(GarmentCategory category) {
    return category == GarmentCategory.top ||
        category == GarmentCategory.bottom ||
        category == GarmentCategory.dress ||
        category == GarmentCategory.outerwear;
  }

  bool _supportsSubcategory(GarmentCategory category) {
    return category == GarmentCategory.outerwear ||
        category == GarmentCategory.shoe ||
        category == GarmentCategory.bag ||
        category == GarmentCategory.accessory ||
        category == GarmentCategory.jewelry;
  }

  String _subcategoryLabel(GarmentCategory category) {
    return switch (category) {
      GarmentCategory.outerwear => 'Outerwear Subcategory',
      GarmentCategory.shoe => 'Shoe Type',
      GarmentCategory.bag => 'Bag Type',
      GarmentCategory.accessory => 'Accessory Type',
      GarmentCategory.jewelry => 'Jewelry Type',
      _ => 'Subcategory',
    };
  }

  bool _supportsStitching(GarmentCategory category) {
    return category == GarmentCategory.top ||
        category == GarmentCategory.bottom ||
        category == GarmentCategory.dress ||
        category == GarmentCategory.outerwear;
  }

  String _titleCase(String value) {
    final String clean = value.trim();
    if (clean.isEmpty) {
      return '';
    }

    return clean
        .split(RegExp(r'\s+'))
        .map(
          (String word) => word.isEmpty
              ? word
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _LendingSection extends StatelessWidget {
  const _LendingSection({
    required this.garment,
    required this.activeLending,
    required this.onMarkReturned,
    required this.isReturning,
    required this.formatDate,
  });

  final Garment garment;
  final AsyncValue<LendingRecord?> activeLending;
  final VoidCallback onMarkReturned;
  final bool isReturning;
  final String Function(DateTime date) formatDate;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: garment.availabilityStatus == GarmentAvailabilityStatus.borrowed
          ? 'Borrowing Information'
          : 'Lending Information',
      child: activeLending.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, _) => const Text('Could Not Load Lending Information.'),
        data: (LendingRecord? record) {
          if (record == null) {
            return const Text('No active lending record was found.');
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _DetailsList(
                values: <String, String?>{
                  (record.direction == LendingDirection.borrowed
                          ? 'Borrowed From'
                          : 'Lent To'):
                      record.personName,
                  (record.direction == LendingDirection.borrowed
                      ? 'Borrowed Date'
                      : 'Lent Date'): formatDate(
                    record.dateOut,
                  ),
                  'Expected Return Date': record.expectedReturnDate == null
                      ? null
                      : formatDate(record.expectedReturnDate!),
                  'Notes': record.notes,
                },
              ),
              if (record.direction == LendingDirection.lent) ...<Widget>[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: isReturning ? null : onMarkReturned,
                  icon: isReturning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.assignment_return_outlined),
                  label: const Text('Mark Returned'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _GarmentDetailTags extends StatelessWidget {
  const _GarmentDetailTags({required this.garment});

  final Garment garment;

  @override
  Widget build(BuildContext context) {
    final List<GarmentColorShade> shades = _colorsForGarment(garment);
    final String sizeLabel = GarmentMetadataFormatter.sizeSummary(
      garment.effectiveSizes,
    );
    final String seasonLabel = GarmentMetadataFormatter.seasonTagLabel(
      garment.seasons,
    );

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        _DetailTag(
          key: const ValueKey<String>('garment-detail-category-tag'),
          label: GarmentMetadataFormatter.categoryLabel(garment.category),
        ),
        _DetailTag(
          key: const ValueKey<String>('garment-detail-availability-tag'),
          label: garment.availabilityStatus.label,
        ),
        if (sizeLabel.isNotEmpty && _supportsSizePersistence(garment.category))
          _DetailTag(
            key: const ValueKey<String>('garment-detail-size-tag'),
            label: sizeLabel,
          ),
        if (shades.isNotEmpty)
          _ColorDetailTag(
            key: const ValueKey<String>('garment-detail-color-tag'),
            shades: shades,
          ),
        if (seasonLabel.isNotEmpty)
          _DetailTag(
            key: const ValueKey<String>('garment-detail-season-tag'),
            label: seasonLabel,
          ),
        _DetailTag(
          key: const ValueKey<String>('garment-detail-laundry-tag'),
          label: garment.laundryStatus.label,
        ),
        if (garment.ironingStatus != null)
          _DetailTag(
            key: const ValueKey<String>('garment-detail-ironing-tag'),
            label: garment.ironingStatus!.label,
          ),
      ],
    );
  }

  static List<GarmentColorShade> _colorsForGarment(Garment garment) {
    if (garment.colorShades.isNotEmpty) {
      return normalizeColorShades(garment.colorShades);
    }

    final String? name = garment.colorName?.trim();
    if (name == null || name.isEmpty) {
      return const <GarmentColorShade>[];
    }

    return <GarmentColorShade>[
      GarmentColorShade(
        name: name,
        hex: garment.colorHex ?? '#CCCCCC',
        isPrimary: true,
      ),
    ];
  }
}

class _DetailTag extends StatelessWidget {
  const _DetailTag({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: _tagTextStyle(context),
        ),
      ),
    );
  }
}

class _ColorDetailTag extends StatelessWidget {
  const _ColorDetailTag({super.key, required this.shades});

  final List<GarmentColorShade> shades;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int index = 0; index < shades.length; index++) ...<Widget>[
              if (index > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '·',
                    style: _tagTextStyle(context)?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: SizedBox.square(
                  dimension: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _colorFromHex(shades[index].hex),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Text(shades[index].name, style: _tagTextStyle(context)),
            ],
          ],
        ),
      ),
    );
  }

  Color _colorFromHex(String hex) {
    final String clean = hex.replaceFirst('#', '').trim();
    final int? value = int.tryParse(clean, radix: 16);
    if (value == null) {
      return const Color(0xFFCCCCCC);
    }

    return Color(0xFF000000 | value);
  }
}

TextStyle? _tagTextStyle(BuildContext context) {
  return Theme.of(
    context,
  ).textTheme.labelMedium?.copyWith(fontSize: 12);
}

bool _supportsSizePersistence(GarmentCategory category) {
  return category == GarmentCategory.top ||
      category == GarmentCategory.bottom ||
      category == GarmentCategory.dress ||
      category == GarmentCategory.outerwear ||
      category == GarmentCategory.shoe;
}

class _WearEntryData {
  const _WearEntryData({
    required this.wornDate,
    this.eventName,
    this.notes,
    this.laundryStatusAfter,
  });

  final DateTime wornDate;
  final String? eventName;
  final String? notes;
  final LaundryStatus? laundryStatusAfter;
}

class _WearEntryDialog extends StatefulWidget {
  const _WearEntryDialog({required this.onSubmit});

  final Future<bool> Function(_WearEntryData data) onSubmit;

  @override
  State<_WearEntryDialog> createState() => _WearEntryDialogState();
}

class _WearEntryDialogState extends State<_WearEntryDialog> {
  static const String _otherEventValue = 'Other';
  static const List<String> _eventOptions = <String>[
    'College / University',
    'Work',
    'Wedding',
    'Party',
    'Formal Event',
    'Travel',
    'Religious Event',
    'Family Gathering',
    'Dinner',
    'Sports / Workout',
    _otherEventValue,
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _customEventController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime _selectedWornDate = DateTime.now();
  String? _selectedEvent;
  LaundryStatus? _selectedLaundryStatus;
  bool _submitting = false;

  @override
  void dispose() {
    _customEventController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime today = DateTime.now();
    final DateTime nowDate = DateTime(today.year, today.month, today.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedWornDate.isAfter(nowDate)
          ? nowDate
          : _selectedWornDate,
      firstDate: DateTime(today.year - 5),
      lastDate: nowDate,
      helpText: 'When Was This Garment Worn?',
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _selectedWornDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    final String customEvent = _customEventController.text.trim();
    final String notes = _notesController.text.trim();
    final String? eventName = _selectedEvent == null
        ? null
        : _selectedEvent == _otherEventValue
        ? customEvent
        : _selectedEvent;
    final String cleanEventName = eventName?.trim() ?? '';

    final bool success;
    try {
      success = await widget.onSubmit(
        _WearEntryData(
          wornDate: _selectedWornDate,
          eventName: cleanEventName.isEmpty ? null : cleanEventName,
          notes: notes.isEmpty ? null : notes,
          laundryStatusAfter: _selectedLaundryStatus,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _submitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could Not Record This Wear.')),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    if (!success) {
      setState(() {
        _submitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could Not Record This Wear.')),
      );
      return;
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mark As Worn'),
      content: SizedBox(
        width: double.maxFinite,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  InkWell(
                    onTap: _submitting ? null : _pickDate,
                    borderRadius: BorderRadius.circular(4),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Worn On',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(_formatWornDate(_selectedWornDate)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    initialValue: _selectedEvent,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Event'),
                    items: <DropdownMenuItem<String?>>[
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No Event'),
                      ),
                      ..._eventOptions.map(
                        (String event) => DropdownMenuItem<String?>(
                          value: event,
                          child: Text(event),
                        ),
                      ),
                    ],
                    onChanged: _submitting
                        ? null
                        : (String? value) {
                            setState(() {
                              _selectedEvent = value;
                              if (value != _otherEventValue) {
                                _customEventController.clear();
                              }
                            });
                          },
                  ),
                  if (_selectedEvent == _otherEventValue) ...<Widget>[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _customEventController,
                      enabled: !_submitting,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Custom Event',
                        hintText: 'For example: School Picnic',
                      ),
                      validator: (String? value) {
                        if (_selectedEvent != _otherEventValue) {
                          return null;
                        }

                        if ((value ?? '').trim().isEmpty) {
                          return 'Enter a custom event.';
                        }

                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    enabled: !_submitting,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Optional notes about this wear',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<LaundryStatus?>(
                    initialValue: _selectedLaundryStatus,
                    decoration: const InputDecoration(
                      labelText: 'Laundry Action',
                      prefixIcon: Icon(Icons.local_laundry_service_outlined),
                    ),
                    items: const <DropdownMenuItem<LaundryStatus?>>[
                      DropdownMenuItem<LaundryStatus?>(
                        value: null,
                        child: Text('No Change'),
                      ),
                      DropdownMenuItem<LaundryStatus?>(
                        value: LaundryStatus.dirty,
                        child: Text('Needs Washing'),
                      ),
                    ],
                    onChanged: _submitting
                        ? null
                        : (LaundryStatus? value) {
                            setState(() {
                              _selectedLaundryStatus = value;
                            });
                          },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: const Text('Record Wear'),
        ),
      ],
    );
  }

  String _formatWornDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _DetailsList extends StatelessWidget {
  const _DetailsList({required this.values});

  final Map<String, String?> values;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: values.entries
          .where(
            (MapEntry<String, String?> entry) =>
                entry.value != null && entry.value!.trim().isNotEmpty,
          )
          .map(
            (MapEntry<String, String?> entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: 132,
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Expanded(child: Text(entry.value!)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
