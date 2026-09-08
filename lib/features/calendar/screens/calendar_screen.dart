import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/core/theme/app_dimensions.dart';
import 'package:digital_wardrobe_app/core/theme/app_radius.dart';
import 'package:digital_wardrobe_app/core/theme/app_spacing.dart';
import 'package:digital_wardrobe_app/core/widgets/app_card.dart';
import 'package:digital_wardrobe_app/core/widgets/app_empty_state.dart';
import 'package:digital_wardrobe_app/core/widgets/app_loading_state.dart';
import 'package:digital_wardrobe_app/core/widgets/app_section_header.dart';
import 'package:digital_wardrobe_app/core/widgets/back_arrow_button.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/outfit.dart';
import 'package:digital_wardrobe_app/data/models/wear_log.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/garment_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({
    super.key,
    this.canNavigateBack = false,
    this.onNavigateBack,
  });

  final bool canNavigateBack;
  final VoidCallback? onNavigateBack;

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final activity = ref.watch(calendarMonthProvider(_month));
    final DateTime? selectedDay = ref.watch(selectedCalendarDayProvider);
    final dayHistory = ref.watch(selectedDayWearHistoryProvider);
    final garments =
        ref.watch(garmentsProvider).valueOrNull ?? const <Garment>[];
    final outfits = ref.watch(outfitsProvider).valueOrNull ?? const <Outfit>[];

    return Scaffold(
      appBar: AppBar(
        leading: widget.canNavigateBack
            ? BackArrowButton(onPressed: widget.onNavigateBack)
            : null,
      ),
      body: activity.when(
        loading: () => const AppLoadingState(
          showIcon: false,
          label: 'Loading your calendar',
        ),
        error: (_, _) => AppErrorState(
          title: 'We could not load your calendar',
          message: 'Check your connection and try again.',
          onAction: () => ref.invalidate(calendarMonthProvider(_month)),
        ),
        data: (List<WearLog> logs) {
          final Set<int> activeDays = logs
              .map((WearLog log) => log.wornDate.day)
              .toSet();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(calendarMonthProvider(_month));
              ref.invalidate(selectedDayWearHistoryProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.xxxl,
              ),
              children: <Widget>[
                _CalendarHeader(activeDayCount: activeDays.length),
                const SizedBox(height: AppSpacing.lg),
                _MonthHeader(
                  month: _month,
                  onPrevious: () => setState(() {
                    _month = DateTime(_month.year, _month.month - 1);
                    ref
                        .read(selectedCalendarDayProvider.notifier)
                        .state = null;
                  }),
                  onNext: () => setState(() {
                    _month = DateTime(_month.year, _month.month + 1);
                    ref
                        .read(selectedCalendarDayProvider.notifier)
                        .state = null;
                  }),
                ),
                const SizedBox(height: AppSpacing.md),
                _MonthGrid(
                  month: _month,
                  activeDays: activeDays,
                  selectedDay: selectedDay,
                  onSelect: (DateTime day) =>
                      ref.read(selectedCalendarDayProvider.notifier).state = day,
                ),
                const SizedBox(height: AppSpacing.xxl),
                _DayDetails(
                  selectedDay: selectedDay,
                  dayHistory: dayHistory,
                  garments: garments,
                  outfits: outfits,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({required this.activeDayCount});

  final int activeDayCount;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;

    final String count = activeDayCount == 0
        ? 'No wear recorded this month'
        : activeDayCount == 1
        ? '1 day with wear activity'
        : '$activeDayCount days with wear activity';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text('Calendar', style: textTheme.headlineMedium),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          count,
          style: textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Row(
      children: <Widget>[
        IconButton(
          onPressed: onPrevious,
          tooltip: 'Previous month',
          style: IconButton.styleFrom(
            backgroundColor: colors.surfaceContainerHighest,
            foregroundColor: colors.onSurface,
            shape: const CircleBorder(),
          ),
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${_monthName(month.month)} ${month.year}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          tooltip: 'Next month',
          style: IconButton.styleFrom(
            backgroundColor: colors.surfaceContainerHighest,
            foregroundColor: colors.onSurface,
            shape: const CircleBorder(),
          ),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.activeDays,
    required this.selectedDay,
    required this.onSelect,
  });

  final DateTime month;
  final Set<int> activeDays;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final int leading = DateTime(month.year, month.month).weekday % 7;
    final int days = DateTime(month.year, month.month + 1, 0).day;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double cellSide = (constraints.maxWidth / 7)
            .clamp(AppDimensions.controlSm, 56.0)
            .toDouble();
        final double radius = cellSide / 2;

        return Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                for (final String day in const <String>[
                  'S',
                  'M',
                  'T',
                  'W',
                  'T',
                  'F',
                  'S',
                ])
                  Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: leading + days,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisExtent: cellSide,
              ),
              itemBuilder: (BuildContext context, int index) {
                if (index < leading) return const SizedBox();
                final int day = index - leading + 1;
                final DateTime date = DateTime(month.year, month.month, day);
                final bool active = activeDays.contains(day);
                final bool selected =
                    selectedDay != null && _sameDay(selectedDay!, date);
                final ColorScheme colors = Theme.of(context).colorScheme;
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: InkWell(
                    onTap: () => onSelect(date),
                    borderRadius: BorderRadius.circular(radius),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: selected
                            ? colors.primary
                            : active
                            ? colors.primaryContainer
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          Text(
                            '$day',
                            style: TextStyle(
                              color: selected ? colors.onPrimary : null,
                            ),
                          ),
                          if (active)
                            Positioned(
                              bottom: AppSpacing.xs,
                              child: Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? colors.onPrimary
                                      : colors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _DayDetails extends ConsumerWidget {
  const _DayDetails({
    required this.selectedDay,
    required this.dayHistory,
    required this.garments,
    required this.outfits,
  });

  final DateTime? selectedDay;
  final AsyncValue<List<WearLog>> dayHistory;
  final List<Garment> garments;
  final List<Outfit> outfits;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime? day = selectedDay;
    if (day == null) {
      return const AppEmptyState(
        icon: Icons.calendar_month_outlined,
        title: 'Select a day',
        message: 'Tap a highlighted day to see garments and outfits worn.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AppSectionHeader(_formatLongDate(day)),
        const SizedBox(height: AppSpacing.xs),
        dayHistory.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: AppLoadingState(
              showIcon: false,
              label: 'Loading day history',
            ),
          ),
          error: (_, _) => AppErrorState(
            title: 'Day history unavailable',
            message: 'We could not load what was worn on this date.',
            onAction: () => ref.invalidate(selectedDayWearHistoryProvider),
          ),
          data: (List<WearLog> dayLogs) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (dayLogs.isEmpty)
                const AppEmptyState(
                  icon: Icons.event_note_outlined,
                  title: 'Nothing worn this day',
                  message:
                      'No garments or outfits were recorded for this date.',
                )
              else
                ..._buildWearTiles(dayLogs, garments, outfits),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () => context.push('/ootd/plan/${_dateKey(day)}'),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Plan outfit for this date'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildWearTiles(
    List<WearLog> logs,
    List<Garment> garments,
    List<Outfit> outfits,
  ) {
    final List<WearLog> soloLogs = <WearLog>[];
    final Map<String, List<WearLog>> byOutfit = <String, List<WearLog>>{};

    for (final WearLog log in logs) {
      if (log.outfitId == null) {
        soloLogs.add(log);
      } else {
        byOutfit.putIfAbsent(log.outfitId!, () => <WearLog>[]).add(log);
      }
    }

    final List<Widget> tiles = <Widget>[
      for (final WearLog log in soloLogs)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _DayWearTile(
            garment: garments
                .where((Garment item) => item.id == log.garmentId)
                .firstOrNull,
            wornDate: log.wornDate,
          ),
        ),
    ];

    for (final MapEntry<String, List<WearLog>> entry in byOutfit.entries) {
      final Outfit? outfit = outfits
          .where((Outfit item) => item.id == entry.key)
          .firstOrNull;

      if (outfit == null) {
        tiles.addAll(
          entry.value.map(
            (WearLog log) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _DayWearTile(
                garment: garments
                    .where((Garment item) => item.id == log.garmentId)
                    .firstOrNull,
                wornDate: log.wornDate,
              ),
            ),
          ),
        );
        continue;
      }

      tiles.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _OutfitWearTile(
            outfit: outfit,
            garments: entry.value
                .map(
                  (WearLog log) => garments
                      .where((Garment item) => item.id == log.garmentId)
                      .firstOrNull,
                )
                .whereType<Garment>()
                .toList(),
            wornDate: entry.value.first.wornDate,
          ),
        ),
      );
    }

    return tiles;
  }
}

class _OutfitWearTile extends StatelessWidget {
  const _OutfitWearTile({
    required this.outfit,
    required this.garments,
    required this.wornDate,
  });

  final Outfit outfit;
  final List<Garment> garments;
  final DateTime wornDate;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            SizedBox(
              width: AppDimensions.touchTarget,
              height: AppDimensions.touchTarget,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: GarmentImage(imageUrl: outfit.coverPhotoUrl),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    outfit.name ?? 'Untitled outfit',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Outfit worn ${_formatShortDate(wornDate)}'
                    '${garments.isEmpty ? '' : ' \u00b7 ${garments.length} garment${garments.length == 1 ? '' : 's'}'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (garments.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: AppDimensions.controlMd,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: garments.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (BuildContext context, int index) {
                final Garment garment = garments[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: GarmentImage(imageUrl: garment.coverImageUrl),
                );
              },
            ),
          ),
        ],
      ],
    ),
  );
}

class _DayWearTile extends StatelessWidget {
  const _DayWearTile({
    required this.garment,
    required this.wornDate,
  });

  final Garment? garment;
  final DateTime wornDate;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: AppDimensions.touchTarget,
            height: AppDimensions.touchTarget,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: GarmentImage(imageUrl: garment?.coverImageUrl),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  garment?.name ?? 'In Closet Vault',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Worn ${_formatShortDate(wornDate)}',
                  style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

bool _sameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

String _monthName(int month) => const <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
][month - 1];
String _formatLongDate(DateTime date) =>
    '${_monthName(date.month)} ${date.day}, ${date.year}';
String _formatShortDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

String _dateKey(DateTime date) {
  final String month = date.month.toString().padLeft(2, '0');
  final String day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}