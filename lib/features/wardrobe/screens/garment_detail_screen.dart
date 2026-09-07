import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/core/theme/app_dimensions.dart';
import 'package:digital_wardrobe_app/core/theme/app_radius.dart';
import 'package:digital_wardrobe_app/core/theme/app_spacing.dart';
import 'package:digital_wardrobe_app/core/widgets/app_empty_state.dart';
import 'package:digital_wardrobe_app/core/widgets/app_loading_state.dart';
import 'package:digital_wardrobe_app/core/widgets/back_arrow_button.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/lending_record.dart';
import 'package:digital_wardrobe_app/data/models/wear_log.dart';
import 'package:digital_wardrobe_app/features/wardrobe/utils/garment_metadata_formatter.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/garment_metadata_section.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/garment_photo_carousel.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/garment_wear_insight.dart';
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
          loading: () => Scaffold(
            appBar: AppBar(leading: const BackArrowButton()),
            body: const AppLoadingState(
              showIcon: false,
              label: 'Loading garment',
            ),
          ),
          error: (_, _) => Scaffold(
            appBar: AppBar(leading: const BackArrowButton()),
            body: AppErrorState(
              title: 'Garment unavailable',
              message: 'This garment could not be loaded. Try again.',
              onAction: () => ref.invalidate(garmentProvider(garmentId)),
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
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xl,
                    AppSpacing.xl,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        garment.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineLarge?.copyWith(height: 1.1),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _GarmentSubtitle(garment: garment),
                      const SizedBox(height: AppSpacing.sm),
                      _GarmentDetailTags(garment: garment),
                      const SizedBox(height: AppSpacing.xl),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: <Widget>[
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
                          if (!garment.isArchived)
                            PopupMenuButton<GarmentAvailabilityStatus>(
                              tooltip: 'Change Status',
                              onSelected: (status) =>
                                  _changeStatus(context, ref, garment, status),
                              itemBuilder: (BuildContext menuContext) =>
                                  GarmentAvailabilityStatus.values
                                      .map(
                                        (status) =>
                                            PopupMenuItem<
                                              GarmentAvailabilityStatus
                                            >(
                                              value: status,
                                              child: Text(status.label),
                                            ),
                                      )
                                      .toList(),
                              offset: const Offset(0, 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Icon(
                                      Icons.swap_horiz,
                                      size: 18,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSecondaryContainer,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Change Status',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSecondaryContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (!garment.isArchived &&
                              _isClothing(garment.category))
                            Tooltip(
                              message: 'Update Ironing Status',
                              child: InkWell(
                                key: const ValueKey(
                                  'garment-detail-ironing-status-action',
                                ),
                                borderRadius: BorderRadius.circular(20),
                                onTap: () =>
                                    _editIroningStatus(context, ref, garment),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Icon(
                                        Icons.iron_outlined,
                                        size: 18,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSecondaryContainer,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Ironing Status',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSecondaryContainer,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.sm,
                    AppSpacing.xl,
                    AppSpacing.xxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      GarmentWearInsight(garment: garment),
                      const SizedBox(height: AppSpacing.xxl),
                      if (garment.availabilityStatus ==
                              GarmentAvailabilityStatus.lent ||
                          garment.availabilityStatus ==
                              GarmentAvailabilityStatus.borrowed) ...<Widget>[
                        const SizedBox(height: AppSpacing.lg),
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
                        const SizedBox(height: AppSpacing.xxl),
                        GarmentMetadataSection(
                          title: 'Care & Readiness',
                          children: <Widget>[
                            GarmentInfoRow(
                              label: 'Wash Instructions',
                              value: garment.washInstructions!,
                              icon: Icons.local_laundry_service_outlined,
                            ),
                          ],
                        ),
                      ],
                      if (_hasStandaloneGarmentInformation(
                        garment,
                      )) ...<Widget>[
                        const SizedBox(height: AppSpacing.xxl),
                        if ((garment.locationName?.trim().isNotEmpty ?? false))
                          GarmentInfoRow(
                            label: 'Location',
                            value: garment.locationName!,
                            icon: Icons.place_outlined,
                          ),
                        if (garment.occasions.any(
                          (String o) => o.trim().isNotEmpty,
                        ))
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.lg),
                            child: GarmentInfoRow(
                              label: 'Occasions',
                              value: GarmentMetadataFormatter.detailListSummary(
                                garment.occasions.map(_titleCase).toList(),
                              ),
                              icon: Icons.celebration_outlined,
                            ),
                          ),
                        if (garment.moods.any(
                          (String m) => m.trim().isNotEmpty,
                        ))
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.lg),
                            child: GarmentInfoRow(
                              label: 'Moods',
                              value: GarmentMetadataFormatter.detailListSummary(
                                garment.moods.map(_titleCase).toList(),
                              ),
                              icon: Icons.style_outlined,
                            ),
                          ),
                      ],
                      if (_hasGarmentDetails(garment)) ...<Widget>[
                        const SizedBox(height: AppSpacing.xxl),
                        GarmentMetadataSection(
                          title: 'Item Details',
                          children: <Widget>[
                            if (_supportsSubcategory(garment.category) &&
                                (garment.subcategory?.trim().isNotEmpty ??
                                    false))
                              GarmentInfoRow(
                                label: _subcategoryLabel(garment.category),
                                value: garment.subcategory!,
                              ),
                            if (_supportsSizes(garment.category) &&
                                garment.effectiveSizes.isNotEmpty)
                              GarmentInfoRow(
                                label: 'Size',
                                value: garment.effectiveSizes.join(', '),
                                icon: Icons.straighten_outlined,
                              ),
                            if (_isClothing(garment.category)) ...<Widget>[
                              if ((garment.fabric?.trim().isNotEmpty ?? false))
                                GarmentInfoRow(
                                  label: 'Fabric',
                                  value: garment.fabric!,
                                ),
                              if ((garment.fit?.trim().isNotEmpty ?? false))
                                GarmentInfoRow(
                                  label: 'Fit',
                                  value: garment.fit!,
                                ),
                              if ((garment.pattern?.trim().isNotEmpty ?? false))
                                GarmentInfoRow(
                                  label: 'Pattern',
                                  value: garment.pattern!,
                                ),
                              if ((garment.fabricWeight?.trim().isNotEmpty ??
                                  false))
                                GarmentInfoRow(
                                  label: 'Fabric Weight',
                                  value: garment.fabricWeight!,
                                ),
                            ],
                            if (_supportsSleeveLength(garment.category) &&
                                (garment.sleeveLength?.trim().isNotEmpty ??
                                    false))
                              GarmentInfoRow(
                                label: 'Sleeve Length',
                                value: garment.sleeveLength!,
                              ),
                            if (_supportsStitching(garment.category) &&
                                garment.stitchingStatus != null)
                              GarmentInfoRow(
                                label: 'Stitching',
                                value: garment.stitchingStatus!.label,
                              ),

                            if (garment.details?.trim().isNotEmpty ?? false)
                              GarmentInfoRow(
                                label: 'Details',
                                value: garment.details!,
                              ),
                          ],
                        ),
                      ],
                      if (_hasPurchaseInformation(garment)) ...<Widget>[
                        const SizedBox(height: AppSpacing.xxl),
                        GarmentMetadataSection(
                          title: 'Purchase Information',
                          children: <Widget>[
                            if (garment.brand?.trim().isNotEmpty ?? false)
                              GarmentInfoRow(
                                label: 'Brand',
                                value: garment.brand!,
                                icon: Icons.sell_outlined,
                              ),
                            if (garment.purchaseStore?.trim().isNotEmpty ??
                                false)
                              GarmentInfoRow(
                                label: 'Store',
                                value: garment.purchaseStore!,
                              ),
                            if (garment.price != null)
                              GarmentInfoRow(
                                label: 'Price',
                                value:
                                    '${garment.currency} '
                                    '${garment.price!.toStringAsFixed(0)}',
                              ),
                            if (garment.purchaseDate != null)
                              GarmentInfoRow(
                                label: 'Purchase Date',
                                value: _formatDate(garment.purchaseDate!),
                              ),
                            if (_hasReceipt(garment))
                              GarmentInfoRow(
                                label: 'Receipt',
                                value: 'Receipt attached',
                                icon: Icons.receipt_long_outlined,
                                trailing: IconButton(
                                  onPressed: () =>
                                      _previewReceipt(context, garment),
                                  icon: const Icon(
                                    Icons.visibility_outlined,
                                    size: 18,
                                  ),
                                  tooltip: 'View Receipt',
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xxl),
                      GarmentMetadataSection(
                        title: 'Wear History',
                        children: <Widget>[
                          history.when(
                            loading: () =>
                                const AppLoadingState(showIcon: false),
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
                        ],
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

  Future<void> _changeStatus(
    BuildContext context,
    WidgetRef ref,
    Garment garment,
    GarmentAvailabilityStatus status,
  ) async {
    if (status == garment.availabilityStatus) {
      return;
    }

    final bool isLending =
        status == GarmentAvailabilityStatus.lent ||
        status == GarmentAvailabilityStatus.borrowed;

    _LendingEntryData? lending;
    if (isLending) {
      lending = await showDialog<_LendingEntryData>(
        context: context,
        builder: (BuildContext dialogContext) {
          return _LendingEntryDialog(lendDirection: status);
        },
      );

      if (lending == null || !context.mounted) {
        return;
      }
    }

    final FamilyMember? member = ref.read(selectedFamilyMemberProvider);
    if (member == null || !context.mounted) {
      return;
    }

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    try {
      await ref
          .read(garmentRepositoryProvider)
          .updateAvailabilityStatus(
            garmentId: garment.id,
            memberId: member.id,
            status: status,
          );

      await ref
          .read(lendingRepositoryProvider)
          .syncForAvailability(
            memberId: member.id,
            garmentId: garment.id,
            status: status,
            personName: lending?.personName,
            dateOut: lending?.dateOut,
            expectedReturnDate: lending?.expectedReturnDate,
            notes: lending?.notes,
          );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('Could Not Update This Garment Status.')),
      );
      return;
    }

    if (!context.mounted) {
      return;
    }

    ref.invalidate(garmentProvider(garmentId));
    ref.invalidate(garmentsProvider);
    ref.invalidate(activeLendingRecordProvider(garmentId));

    messenger.showSnackBar(
      SnackBar(content: Text('Status Updated To ${status.label}.')),
    );
  }

  Future<void> _editIroningStatus(
    BuildContext context,
    WidgetRef ref,
    Garment garment,
  ) async {
    final IroningStatus? selected = await showDialog<IroningStatus?>(
      context: context,
      builder: (BuildContext dialogContext) {
        return SimpleDialog(
          title: const Text('Ironing Status'),
          children: <Widget>[
            for (final IroningStatus option in IroningStatus.values)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, option),
                child: Text(option.label),
              ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, null),
              child: const Text('Not specified'),
            ),
          ],
        );
      },
    );

    if (selected == garment.ironingStatus || !context.mounted) {
      return;
    }

    final FamilyMember? member = ref.read(selectedFamilyMemberProvider);
    if (member == null || !context.mounted) {
      return;
    }

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    try {
      await ref
          .read(garmentRepositoryProvider)
          .updateIroningStatus(
            garmentId: garment.id,
            memberId: member.id,
            status: selected,
          );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('Could Not Update Ironing Status.')),
      );
      return;
    }

    if (!context.mounted) {
      return;
    }

    ref.invalidate(garmentProvider(garmentId));
    ref.invalidate(garmentsProvider);

    messenger.showSnackBar(SnackBar(content: Text('Ironing Status Updated.')));
  }

  void _previewReceipt(BuildContext context, Garment garment) {
    final String? url = garment.receiptUrl;
    if (url == null || url.isEmpty) {
      return;
    }

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                  child: Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          'Purchase Receipt',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: InteractiveViewer(
                      maxScale: 4,
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) {
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(Icons.broken_image_outlined, size: 40),
                                SizedBox(height: 12),
                                Text('Could not load receipt image.'),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _hasStandaloneGarmentInformation(Garment garment) {
    return (garment.locationName?.trim().isNotEmpty ?? false) ||
        garment.occasions.any(
          (String occasion) => occasion.trim().isNotEmpty,
        ) ||
        garment.moods.any((String mood) => mood.trim().isNotEmpty);
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
    final bool sizesPresent =
        _supportsSizes(garment.category) && garment.effectiveSizes.isNotEmpty;

    return subcategoryDetails ||
        clothingDetails ||
        _isClothing(garment.category) ||
        sizesPresent ||
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
        garment.purchaseDate != null ||
        _hasReceipt(garment);
  }

  bool _hasReceipt(Garment garment) {
    return garment.receiptPath?.trim().isNotEmpty ?? false;
  }

  bool _supportsSizes(GarmentCategory category) {
    return category == GarmentCategory.top ||
        category == GarmentCategory.bottom ||
        category == GarmentCategory.dress ||
        category == GarmentCategory.outerwear ||
        category == GarmentCategory.shoe;
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
    return true;
  }

  String _subcategoryLabel(GarmentCategory category) {
    return switch (category) {
      GarmentCategory.top => 'Tops Subcategory',
      GarmentCategory.bottom => 'Bottoms Subcategory',
      GarmentCategory.dress => 'Dresses Subcategory',
      GarmentCategory.outerwear => 'Outerwear Subcategory',
      GarmentCategory.activewear => 'Activewear Type',
      GarmentCategory.sleepwear => 'Sleepwear Type',
      GarmentCategory.shoe => 'Shoe Type',
      GarmentCategory.watches => 'Watch Type',
      GarmentCategory.jewelry => 'Jewelry Type',
      GarmentCategory.bag => 'Bag Type',
      GarmentCategory.accessory => 'Accessory Type',
      _ => 'Category Label',
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

/// Editorial subtitle line: "Category · Signature material · Season"
class _GarmentSubtitle extends StatelessWidget {
  const _GarmentSubtitle({required this.garment});

  final Garment garment;

  @override
  Widget build(BuildContext context) {
    final String category = GarmentMetadataFormatter.categoryLabel(
      garment.category,
    );
    final List<String> parts = <String>[
      category,
      if (garment.fabric?.trim().isNotEmpty ?? false) garment.fabric!,
      ...(() {
        final String season = GarmentMetadataFormatter.seasonTagLabel(
          garment.seasons,
        );
        return season.isEmpty ? const <String>[] : <String>[season];
      })(),
    ];

    return Text(
      parts.join(' · '),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
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
    return GarmentMetadataSection(
      title: garment.availabilityStatus == GarmentAvailabilityStatus.borrowed
          ? 'Borrowing Information'
          : 'Lending Information',
      children: <Widget>[
        activeLending.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => const Text('Could Not Load Lending Information.'),
          data: (LendingRecord? record) {
            if (record == null) {
              return const Text('No active lending record was found.');
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                GarmentInfoRow(
                  label: (record.direction == LendingDirection.borrowed
                      ? 'Borrowed From'
                      : 'Lent To'),
                  value: record.personName,
                ),
                GarmentInfoRow(
                  label: (record.direction == LendingDirection.borrowed
                      ? 'Borrowed Date'
                      : 'Lent Date'),
                  value: formatDate(record.dateOut),
                ),
                if (record.expectedReturnDate != null)
                  GarmentInfoRow(
                    label: 'Expected Return Date',
                    value: formatDate(record.expectedReturnDate!),
                  ),
                if (record.notes?.trim().isNotEmpty ?? false)
                  GarmentInfoRow(label: 'Notes', value: record.notes!),
                if (record.direction == LendingDirection.lent) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
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
      ],
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
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
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
        borderRadius: AppRadius.stadium,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Text(label, style: _tagTextStyle(context)),
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
        borderRadius: AppRadius.stadium,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int index = 0; index < shades.length; index++) ...<Widget>[
              if (index > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs + 2,
                  ),
                  child: Text(
                    '\u00b7',
                    style: _tagTextStyle(context)?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: SizedBox.square(
                  dimension: AppSpacing.sm,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _colorFromHex(shades[index].hex),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
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
  ).textTheme.labelMedium?.copyWith(fontSize: AppDimensions.iconMd);
}

bool _supportsSizePersistence(GarmentCategory category) {
  return category == GarmentCategory.top ||
      category == GarmentCategory.bottom ||
      category == GarmentCategory.dress ||
      category == GarmentCategory.outerwear ||
      category == GarmentCategory.shoe;
}

class _LendingEntryData {
  const _LendingEntryData({
    required this.personName,
    required this.dateOut,
    this.expectedReturnDate,
    this.notes,
  });

  final String personName;
  final DateTime dateOut;
  final DateTime? expectedReturnDate;
  final String? notes;
}

class _LendingEntryDialog extends StatefulWidget {
  const _LendingEntryDialog({required this.lendDirection});

  final GarmentAvailabilityStatus lendDirection;

  @override
  State<_LendingEntryDialog> createState() => _LendingEntryDialogState();
}

class _LendingEntryDialogState extends State<_LendingEntryDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _personController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime _selectedDateOut = DateTime.now();
  DateTime? _expectedReturnDate;
  bool _submitting = false;

  bool get _isLent => widget.lendDirection == GarmentAvailabilityStatus.lent;

  @override
  void dispose() {
    _personController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOut() async {
    final DateTime today = DateTime.now();
    final DateTime nowDate = DateTime(today.year, today.month, today.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOut.isAfter(nowDate)
          ? nowDate
          : _selectedDateOut,
      firstDate: DateTime(today.year - 5),
      lastDate: nowDate,
      helpText: _isLent ? 'When Was It Lent?' : 'When Was It Borrowed?',
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _selectedDateOut = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _pickExpectedReturn() async {
    final DateTime today = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expectedReturnDate ?? _selectedDateOut,
      firstDate: _selectedDateOut,
      lastDate: DateTime(today.year + 5),
      helpText: 'When Is It Expected Back?',
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _expectedReturnDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
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

    final _LendingEntryData data = _LendingEntryData(
      personName: _personController.text.trim(),
      dateOut: _selectedDateOut,
      expectedReturnDate: _expectedReturnDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    Navigator.of(context).pop(data);
  }

  @override
  Widget build(BuildContext context) {
    final String label = _isLent ? 'Lent' : 'Borrowed';

    return AlertDialog(
      title: Text('$label To/From'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _personController,
                enabled: !_submitting,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: _isLent ? 'Lent To' : 'Borrowed From',
                  hintText: _isLent
                      ? 'Who did you lend it to?'
                      : 'Who did you borrow it from?',
                  border: const OutlineInputBorder(),
                ),
                validator: (String? value) {
                  final String clean = value?.trim() ?? '';
                  if (clean.isEmpty) {
                    return 'Enter the person name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _submitting ? null : _pickDateOut,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: _isLent ? 'Lent Date' : 'Borrowed Date',
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(_formatDate(_selectedDateOut)),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _submitting ? null : _pickExpectedReturn,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Expected Return (optional)',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.event_outlined),
                  ),
                  child: Text(
                    _expectedReturnDate == null
                        ? 'Not set'
                        : _formatDate(_expectedReturnDate!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                enabled: !_submitting,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
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
                  const SizedBox(height: AppSpacing.lg),
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
                    const SizedBox(height: AppSpacing.lg),
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
                  const SizedBox(height: AppSpacing.lg),
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
                  const SizedBox(height: AppSpacing.lg),
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
