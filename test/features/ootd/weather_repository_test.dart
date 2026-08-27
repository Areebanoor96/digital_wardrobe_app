import 'dart:io';

import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/ootd/models/weather_data.dart';
import 'package:digital_wardrobe_app/features/ootd/services/location_service.dart';
import 'package:digital_wardrobe_app/features/ootd/services/outfit_recommendation_service.dart';
import 'package:digital_wardrobe_app/features/ootd/services/weather_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const DeviceLocation location = DeviceLocation(
    latitude: 33.6844,
    longitude: 73.0479,
  );

  Map<String, dynamic> validPayload({
    double temperature = 31,
    double latitude = 33.6844,
    double longitude = 73.0479,
  }) {
    return <String, dynamic>{
      'temperature': temperature,
      'feels_like': temperature + 2,
      'min_temperature': temperature - 4,
      'max_temperature': temperature + 5,
      'humidity': 55,
      'rain_probability': 20,
      'wind_speed': 12,
      'uv_index': 6,
      'condition': 'Clear',
      'has_rain_or_snow': false,
      'fetched_at': '2026-08-24T10:00:00.000Z',
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  WeatherRepository repositoryFor(List<dynamic> responses) {
    return WeatherRepository.forTesting((_, _) async => responses.removeAt(0));
  }

  group('WeatherRepository response handling', () {
    test('valid weather response parses normally', () async {
      final WeatherRepository repository = repositoryFor(<dynamic>[
        validPayload(),
      ]);

      final WeatherData? weather = await repository.fetchForLocation(
        location: location,
      );

      expect(weather, isNotNull);
      expect(weather!.temperature, 31);
      expect(weather.condition, 'Clear');
      expect(weather.latitude, location.latitude);
      expect(weather.longitude, location.longitude);
    });

    test('free-weather normalized payload accepts missing UV', () async {
      final Map<String, dynamic> payload = validPayload();
      payload['uv_index'] = null;
      payload['rain_probability'] = 80;
      payload['has_rain_or_snow'] = true;
      payload['condition'] = 'Rain';
      final WeatherRepository repository = repositoryFor(<dynamic>[payload]);

      final WeatherData? weather = await repository.fetchForLocation(
        location: location,
      );

      expect(weather, isNotNull);
      expect(weather!.uvIndex, isNull);
      expect(weather.rainProbability, 80);
      expect(weather.hasRainOrSnow, isTrue);
      expect(weather.condition, 'Rain');
    });

    test('legacy 0-1 precipitation probability is normalized to percent', () {
      final WeatherData weather = WeatherData.fromJson(validPayload()
        ..['rain_probability'] = 0.8);

      expect(weather.rainProbability, 80);
    });

    test('{error: ...} response becomes unavailable weather', () async {
      final WeatherRepository repository = repositoryFor(<dynamic>[
        <String, dynamic>{'error': 'OPENWEATHER_API_KEY is not configured.'},
      ]);

      final WeatherData? weather = await repository.fetchForLocation(
        location: location,
      );

      expect(weather, isNull);
    });

    test('malformed or incomplete map becomes unavailable weather', () async {
      final WeatherRepository repository = repositoryFor(<dynamic>[
        <String, dynamic>{'temperature': 31},
      ]);

      final WeatherData? weather = await repository.fetchForLocation(
        location: location,
      );

      expect(weather, isNull);
    });

    test('failed weather response is not cached', () async {
      int calls = 0;
      final List<dynamic> responses = <dynamic>[
        <String, dynamic>{'error': 'provider failed'},
        validPayload(temperature: 28),
      ];
      final WeatherRepository repository = WeatherRepository.forTesting((
        _,
        _,
      ) async {
        calls++;
        return responses.removeAt(0);
      });

      final WeatherData? failed = await repository.fetchForLocation(
        location: location,
      );
      final WeatherData? recovered = await repository.fetchForLocation(
        location: location,
      );

      expect(failed, isNull);
      expect(recovered?.temperature, 28);
      expect(calls, 2);
    });

    test(
      'OOTD still generates using non-weather rules when weather fails',
      () async {
        final WeatherRepository repository = repositoryFor(<dynamic>[
          <String, dynamic>{'error': 'provider failed'},
        ]);

        final WeatherData? weather = await repository.fetchForLocation(
          location: location,
        );

        const OutfitRecommendationService service =
            OutfitRecommendationService();
        final OutfitRecommendation recommendation = service.recommend(
          allGarments: <Garment>[
            const Garment(
              id: 'top',
              name: 'Top',
              category: GarmentCategory.top,
              photoPaths: <String>[],
              photoUrls: <String>[],
              memberId: 'member-1',
            ),
            const Garment(
              id: 'bottom',
              name: 'Bottom',
              category: GarmentCategory.bottom,
              photoPaths: <String>[],
              photoUrls: <String>[],
              memberId: 'member-1',
            ),
            const Garment(
              id: 'shoes',
              name: 'Shoes',
              category: GarmentCategory.shoe,
              photoPaths: <String>[],
              photoUrls: <String>[],
              memberId: 'member-1',
            ),
          ],
          weather: weather,
          memberId: 'member-1',
          now: DateTime(2026, 8, 24),
        );

        expect(weather, isNull);
        expect(recommendation.garments, isNotEmpty);
        expect(
          recommendation.reasons.join(' '),
          contains('Weather is unavailable'),
        );
      },
    );

    test('weather function source does not use paid endpoint path', () {
      final String source = Directory('supabase/functions/ootd-weather')
          .listSync(recursive: true)
          .whereType<File>()
          .map((File file) => file.readAsStringSync())
          .join('\n');

      expect(source, isNot(contains('/data/' '3.0/')));
      expect(source, isNot(contains('one' 'call')));
    });
  });
}
