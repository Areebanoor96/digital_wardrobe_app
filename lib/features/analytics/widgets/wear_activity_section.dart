import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/core/theme/app_radius.dart';
import 'package:digital_wardrobe_app/core/theme/app_spacing.dart';
import 'package:digital_wardrobe_app/core/widgets/app_card.dart';
import 'package:digital_wardrobe_app/core/widgets/app_empty_state.dart';
import 'package:digital_wardrobe_app/core/widgets/app_loading_state.dart';
import 'package:digital_wardrobe_app/core/widgets/app_section_header.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/wear_log.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/garment_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Compact recent wear activity shown on Analytics.
///
/// Reuses the existing [recentWearActivityProvider] and [garmentsProvider] so
/// Analytics never issues its own wear-history query. The provider already
/// bounds the result to a sensible recent subset, so no extra pagination logic
/// lives here.
class WearActivitySection extends ConsumerWidget {
  const WearActivitySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<WearLog>> activity = ref.watch(
      recentWearActivityProvider,
    );
    final List<Garment> garments =
        ref.watch(garmentsProvider).valueOrNull ?? const <Garment>[];

    return activity.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: AppLoadingState(showIcon: false, label: 'Loading wear activity…'),
      ),
      error: (Object _, StackTrace _) => AppErrorState(
        title: 'We could not load wear activity',
        message: 'Check your connection and try again.',
        onAction: () => ref.invalidate(recentWearActivityProvider),
      ),
      data: (List<WearLog> logs) {
        if (logs.isEmpty) {
          return const AppEmptyState(
            icon: Icons.history,
            title: 'No wear activity yet',
            message:
                'Wear activity will appear here as you log wears for your garments.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AppSectionHeader(
              'Wear activity',
              subtitle: 'Latest ${logs.length} '
                  'wear${logs.length == 1 ? '' : 's'}',
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  for (int index = 0; index < logs.length; index++) ...<Widget>[
                    if (index > 0)
                      const Divider(
                        height: 1,
                        indent: 76,
                        endIndent: AppSpacing.lg,
                      ),
                    _WearActivityTile(
                      log: logs[index],
                      garment: _garmentFor(garments, logs[index].garmentId),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Garment? _garmentFor(List<Garment> garments, String garmentId) {
    for (final Garment garment in garments) {
      if (garment.id == garmentId) {
        return garment;
      }
    }
    return null;
  }
}

class _WearActivityTile extends StatelessWidget {
  const _WearActivityTile({required this.log, required this.garment});

  final WearLog log;
  final Garment? garment;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    final String? categoryLabel = garment?.category.label;
    final String? eventName = log.eventName?.trim();
    final String? detail;

    if (categoryLabel != null &&
        eventName != null &&
        eventName.isNotEmpty) {
      detail = '$categoryLabel · $eventName';
    } else if (categoryLabel != null) {
      detail = categoryLabel;
    } else if (eventName != null && eventName.isNotEmpty) {
      detail = eventName;
    } else {
      detail = null;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      leading: SizedBox(
        width: 48,
        height: 48,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: GarmentImage(imageUrl: garment?.coverImageUrl),
        ),
      ),
      title: Text(
        garment?.name ?? 'In Closet Vault',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: detail == null
          ? null
          : Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(
        formatWearDate(log.wornDate),
        style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}

/// Human-friendly relative wear date. Once a record is older than a day it
/// falls back to a compact `dd/mm/yyyy` form so the trailing label stays short.
String formatWearDate(DateTime date) {
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime day = DateTime(date.year, date.month, date.day);
  final int difference = today.difference(day).inDays;

  if (difference == 0) {
    return 'Today';
  }
  if (difference == 1) {
    return 'Yesterday';
  }

  final String dd = day.day.toString().padLeft(2, '0');
  final String mm = day.month.toString().padLeft(2, '0');
  return '$dd/$mm/${day.year}';
}