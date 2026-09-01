import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/ootd/models/weather_data.dart';
import 'package:digital_wardrobe_app/features/ootd/providers/ootd_provider.dart';
import 'package:digital_wardrobe_app/features/ootd/providers/weather_provider.dart';
import 'package:digital_wardrobe_app/features/ootd/services/outfit_recommendation_service.dart';
import 'package:digital_wardrobe_app/features/outfits/models/outfit_context.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const FamilyMember _member = FamilyMember(
  id: 'member-1',
  name: 'Test Member',
  relationship: RelationshipType.self,
);

Garment _garment({
  required String id,
  required String name,
  required GarmentCategory category,
}) {
  return Garment(
    id: id,
    name: name,
    category: category,
    photoPaths: const <String>[],
    photoUrls: const <String>[],
    memberId: _member.id,
  );
}

final List<Garment> _wardrobe = <Garment>[
  _garment(id: 'top', name: 'White Shirt', category: GarmentCategory.top),
  _garment(id: 'bottom', name: 'Black Pants', category: GarmentCategory.bottom),
  _garment(id: 'shoes', name: 'Sneakers', category: GarmentCategory.shoe),
];

class _CapturedDate {
  DateTime? value;
}

const WeatherData _rainy = WeatherData(rainProbability: 80, condition: 'Rain');

const WeatherData _clearToday = WeatherData(
  temperature: 31,
  condition: 'Clear',
  rainProbability: 0,
);

ProviderContainer _container({
  DateTime? requestedDate,
  WeatherData dateWeather = _rainy,
  _CapturedDate? captured,
}) {
  return ProviderContainer(
    overrides: <Override>[
      garmentsProvider.overrideWith((Ref ref) async => _wardrobe),
      ootdWearHistoryProvider.overrideWith((Ref ref) async => const <Never>[]),
      ootdContextProvider.overrideWith((Ref ref) => const OutfitContext()),
      selectedFamilyMemberProvider.overrideWith((Ref ref) => _member),
      ootdWeatherForDateProvider.overrideWith((
        Ref ref,
        DateTime date,
      ) async {
        captured?.value = DateTime(date.year, date.month, date.day);
        return requestedDate == null ? null : dateWeather;
      }),
      ootdWeatherProvider.overrideWith((Ref ref) async => _clearToday),
    ],
  );
}

/// Warm the async dependencies the OOTD providers watch so the cold
/// `read(...future)` in tests settles deterministically.
Future<void> _warm(ProviderContainer container, DateTime? date) async {
  await container.read(garmentsProvider.future);
  await container.read(ootdWearHistoryProvider.future);
  await container.read(ootdWeatherProvider.future);
  if (date != null) {
    await container.read(ootdWeatherForDateProvider(date).future);
  }
}

void main() {
  test(
    'ootdForDateProvider requests weather for the normalized date only',
    () async {
      final _CapturedDate captured = _CapturedDate();
      final ProviderContainer container = _container(
        requestedDate: DateTime(2026, 9, 5, 14, 30),
        captured: captured,
      );
      addTearDown(container.dispose);
      await _warm(container, DateTime(2026, 9, 5));

      await container.read(ootdForDateProvider(DateTime(2026, 9, 5)).future);

      expect(captured.value, DateTime(2026, 9, 5));
    },
  );

  test('ootdForDateProvider uses that date\'s weather in the engine', () async {
    final ProviderContainer container = _container(
      requestedDate: DateTime(2026, 9, 5),
    );
    addTearDown(container.dispose);
    await _warm(container, DateTime(2026, 9, 5));

    final OutfitRecommendation recommendation = await container.read(
      ootdForDateProvider(DateTime(2026, 9, 5)).future,
    );

    expect(recommendation.garments, isNotEmpty);
    expect(
      recommendation.reasons.join(' '),
      contains('Rain-sensitive fabrics and open footwear are avoided'),
    );
  });

  test(
    'out-of-range date weather is treated as unavailable (non-weather rules)',
    () async {
      final ProviderContainer container = _container(
        requestedDate: DateTime(2026, 12, 31),
        dateWeather: const WeatherData(available: false),
      );
      addTearDown(container.dispose);
      await _warm(container, DateTime(2026, 12, 31));

      final OutfitRecommendation recommendation = await container.read(
        ootdForDateProvider(DateTime(2026, 12, 31)).future,
      );

      // Weather with available == false must be passed to the engine as null,
      // so the non-weather fallback reason is produced (no invented weather).
      expect(recommendation.garments, isNotEmpty);
      expect(
        recommendation.reasons.join(' '),
        contains('Weather is unavailable, so the outfit uses non-weather rules'),
      );
    },
  );

  test('existing ootdProvider still works with today\'s weather', () async {
    final ProviderContainer container = _container();
    addTearDown(container.dispose);
    await _warm(container, null);

    final OutfitRecommendation recommendation = await container.read(
      ootdProvider.future,
    );

    // Clear, warm today weather must not drive rain-specific advice.
    expect(recommendation.garments, isNotEmpty);
    expect(recommendation.reasons.join(' '), isNot(contains('Rain-sensitive')));
  });

  test(
    'date provider and today provider do not share a weather source',
    () async {
      final _CapturedDate captured = _CapturedDate();
      final ProviderContainer container = _container(
        requestedDate: DateTime(2026, 9, 5),
        captured: captured,
      );
      addTearDown(container.dispose);
      await _warm(container, DateTime(2026, 9, 5));

      final OutfitRecommendation today = await container.read(
        ootdProvider.future,
      );
      final OutfitRecommendation planned = await container.read(
        ootdForDateProvider(DateTime(2026, 9, 5)).future,
      );

      // The date request hit the family provider with the normalized date;
      // today's provider used the separate today-weather override.
      expect(captured.value, DateTime(2026, 9, 5));
      expect(today.reasons.join(' '), isNot(contains('Rain-sensitive')));
      expect(
        planned.reasons.join(' '),
        contains('Rain-sensitive fabrics and open footwear are avoided'),
      );
    },
  );
}
