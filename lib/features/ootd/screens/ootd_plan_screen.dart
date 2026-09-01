import 'package:digital_wardrobe_app/core/widgets/back_arrow_button.dart';
import 'package:digital_wardrobe_app/features/ootd/models/weather_data.dart';
import 'package:digital_wardrobe_app/features/ootd/providers/ootd_provider.dart';
import 'package:digital_wardrobe_app/features/ootd/providers/weather_provider.dart';
import 'package:digital_wardrobe_app/features/ootd/services/outfit_recommendation_service.dart';
import 'package:digital_wardrobe_app/features/ootd/widgets/ootd_card.dart';
import 'package:digital_wardrobe_app/features/outfits/models/outfit_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows an OOTD recommendation planned for a specific calendar [date].
///
/// The date is resolved through [ootdForDateProvider], which feeds the
/// requested date and its date-specific weather into the existing
/// [OutfitRecommendationService]. When the forecast window does not cover the
/// date, a clear message is shown and the engine still offers a recommendation
/// based on its non-weather rules (never today's weather).
class OutfitPlanScreen extends ConsumerWidget {
  const OutfitPlanScreen({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime day = DateTime(date.year, date.month, date.day);
    final AsyncValue<OutfitRecommendation> recommendation =
        ref.watch(ootdForDateProvider(day));
    final AsyncValue<WeatherData?> weather =
        ref.watch(ootdWeatherForDateProvider(day));
    final AsyncValue<void> actionState = ref.watch(ootdActionControllerProvider);

    final String title = _formatLongDate(day);

    return Scaffold(
      appBar: AppBar(
        leading: const BackArrowButton(),
        title: const Text('Plan Outfit'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ootdForDateProvider(day));
          ref.invalidate(ootdWeatherForDateProvider(day));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'What should I wear on this day?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            weather.when(
              loading: () => const _WeatherBannerSkeleton(),
              error: (_, _) => const SizedBox.shrink(),
              data: (WeatherData? data) {
                if (data == null) {
                  return const SizedBox.shrink();
                }
                if (!data.available) {
                  return const _WeatherOutOfRangeBanner();
                }
                return _WeatherBanner(weather: data);
              },
            ),
            const SizedBox(height: 12),
            recommendation.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => _PlanFeedback(
                title: 'We could not prepare a suggestion',
                message: 'Check your connection and try again.',
                actionLabel: 'Retry',
                onAction: () {
                  ref.invalidate(ootdForDateProvider(day));
                },
              ),
              data: (OutfitRecommendation rec) => OotdCard(
                recommendation: rec,
                outfitContext: ref.watch(ootdContextProvider),
                onRefresh: () {
                  ref.invalidate(ootdForDateProvider(day));
                  ref.invalidate(ootdWeatherForDateProvider(day));
                },
                onContextChanged: (OutfitContext value) {
                  ref.read(ootdContextProvider.notifier).state = value;
                },
                onSave: actionState.isLoading
                    ? null
                    : (current) => ref
                          .read(ootdActionControllerProvider.notifier)
                          .saveAsOutfit(current.garments),
                onWear: actionState.isLoading
                    ? null
                    : (current) => ref
                          .read(ootdActionControllerProvider.notifier)
                          .wearOutfit(current.garments),
                isSaving: actionState.isLoading,
                isWearing: actionState.isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherBanner extends StatelessWidget {
  const _WeatherBanner({required this.weather});

  final WeatherData weather;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    final double? temp = weather.feelsLike ?? weather.temperature;
    final String temperatureText =
        temp == null ? '' : '${temp.round()}\u00B0';
    final String? condition = weather.condition;
    final double? rain = weather.rainProbability;
    final String rainText = rain == null || rain <= 0
        ? ''
        : ' \u00b7 ${rain.round()}% rain';
    final String range = _rangeText(weather);

    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.cloud_outlined, color: colors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Expected weather',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    <String>[
                      if (temperatureText.isNotEmpty) temperatureText,
                      ?condition,
                      if (range.isNotEmpty) range,
                      if (rainText.isNotEmpty) rainText.trim(),
                    ].join(' \u00b7 '),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
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

  String _rangeText(WeatherData weather) {
    final double? min = weather.minTemperature;
    final double? max = weather.maxTemperature;
    if (min == null && max == null) {
      return '';
    }
    if (min != null && max != null) {
      return '${min.round()}-${max.round()}\u00B0';
    }
    if (min != null) {
      return 'low ${min.round()}\u00B0';
    }
    return 'high ${max!.round()}\u00B0';
  }
}

class _WeatherOutOfRangeBanner extends StatelessWidget {
  const _WeatherOutOfRangeBanner();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colors.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.info_outline, color: colors.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Weather forecast isn't available for this date yet. "
                'The suggestion below uses general wardrobe rules instead.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherBannerSkeleton extends StatelessWidget {
  const _WeatherBannerSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const SizedBox(
        height: 64,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }
}

class _PlanFeedback extends StatelessWidget {
  const _PlanFeedback({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.auto_awesome_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatLongDate(DateTime date) {
  const List<String> months = <String>[
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
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
