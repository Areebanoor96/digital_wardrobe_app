import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/outfit.dart';
import 'package:digital_wardrobe_app/data/models/wear_log.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/garment_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

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
      appBar: AppBar(title: const Text('Calendar')),
      body: activity.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _CalendarFeedback(
          title: 'We could not load your calendar',
          message: 'Check your connection and try again.',
          action: () => ref.invalidate(calendarMonthProvider(_month)),
        ),
        data: (List<WearLog> logs) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(calendarMonthProvider(_month));
            ref.invalidate(selectedDayWearHistoryProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: <Widget>[
              _MonthHeader(
                month: _month,
                onPrevious: () => setState(
                  () => _month = DateTime(_month.year, _month.month - 1),
                ),
                onNext: () => setState(
                  () => _month = DateTime(_month.year, _month.month + 1),
                ),
              ),
              const SizedBox(height: 16),
              _MonthGrid(
                month: _month,
                logs: logs,
                selectedDay: selectedDay,
                onSelect: (DateTime day) =>
                    ref.read(selectedCalendarDayProvider.notifier).state = day,
              ),
              const SizedBox(height: 28),
              Text(
                selectedDay == null
                    ? 'Select a day'
                    : _formatLongDate(selectedDay),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (selectedDay == null)
                const Text(
                  'Tap a highlighted day to see garments and outfits worn.',
                )
              else
                dayHistory.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => TextButton.icon(
                    onPressed: () =>
                        ref.invalidate(selectedDayWearHistoryProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry day history'),
                  ),
                  data: (List<WearLog> dayLogs) => dayLogs.isEmpty
                      ? const Text('No garments were worn on this day.')
                      : Column(
                          children: dayLogs.map((WearLog log) {
                            final Garment? garment = garments
                                .where(
                                  (Garment item) => item.id == log.garmentId,
                                )
                                .firstOrNull;
                            final Outfit? outfit = log.outfitId == null
                                ? null
                                : outfits
                                      .where(
                                        (Outfit item) =>
                                            item.id == log.outfitId,
                                      )
                                      .firstOrNull;
                            return _DayWearTile(
                              garment: garment,
                              outfit: outfit,
                              wornDate: log.wornDate,
                            );
                          }).toList(),
                        ),
                ),
            ],
          ),
        ),
      ),
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
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: <Widget>[
      IconButton(onPressed: onPrevious, icon: const Icon(Icons.chevron_left)),
      Text(
        '${_monthName(month.month)} ${month.year}',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
    ],
  );
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.logs,
    required this.selectedDay,
    required this.onSelect,
  });
  final DateTime month;
  final List<WearLog> logs;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final Set<int> activeDays = logs
        .map((WearLog log) => log.wornDate.day)
        .toSet();
    final int leading = DateTime(month.year, month.month).weekday % 7;
    final int days = DateTime(month.year, month.month + 1, 0).day;
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            for (final String day in <String>[
              'S',
              'M',
              'T',
              'W',
              'T',
              'F',
              'S',
            ])
              Expanded(child: Center(child: Text(day))),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: leading + days,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
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
              padding: const EdgeInsets.all(3),
              child: InkWell(
                onTap: () => onSelect(date),
                borderRadius: BorderRadius.circular(99),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.primary
                        : active
                        ? colors.primaryContainer
                        : null,
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
                          bottom: 5,
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
  }

  bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

class _DayWearTile extends StatelessWidget {
  const _DayWearTile({
    required this.garment,
    required this.outfit,
    required this.wornDate,
  });
  final Garment? garment;
  final Outfit? outfit;
  final DateTime wornDate;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: SizedBox(
      width: 48,
      height: 48,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GarmentImage(imageUrl: garment?.coverImageUrl),
      ),
    ),
    title: Text(garment?.name ?? 'In Closet Vault'),
    subtitle: Text(
      outfit == null
          ? 'Worn ${_formatShortDate(wornDate)}'
          : 'Outfit: ${outfit!.name ?? 'Untitled outfit'} · ${_formatShortDate(wornDate)}',
    ),
  );
}

class _CalendarFeedback extends StatelessWidget {
  const _CalendarFeedback({
    required this.title,
    required this.message,
    this.action,
  });
  final String title;
  final String message;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.calendar_month_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...<Widget>[
            const SizedBox(height: 20),
            FilledButton(onPressed: action, child: const Text('Retry')),
          ],
        ],
      ),
    ),
  );
}

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
