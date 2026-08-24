import 'dart:math';

import 'package:digital_wardrobe_app/features/ootd/models/weather_data.dart';
import 'package:digital_wardrobe_app/features/ootd/services/location_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef WeatherFunctionInvoker =
    Future<dynamic> Function(String functionName, Map<String, double> body);

class WeatherRepository {
  WeatherRepository(this._client) : _invokeWeatherFunction = null;

  WeatherRepository.forTesting(this._invokeWeatherFunction) : _client = null;

  final SupabaseClient? _client;
  final WeatherFunctionInvoker? _invokeWeatherFunction;
  WeatherData? _cached;

  Future<WeatherData?> fetchForLocation({
    required DeviceLocation location,
    bool forceRefresh = false,
  }) async {
    final WeatherData? cached = _cached;
    if (!forceRefresh &&
        cached != null &&
        !cached.isStale &&
        _sameApproximateLocation(cached, location)) {
      return cached;
    }

    final Map<String, double> body = <String, double>{
      'latitude': location.latitude,
      'longitude': location.longitude,
    };

    final dynamic data = await _invokeFunction(body);
    final WeatherData? weather = _parseWeatherPayload(data);
    if (weather == null) {
      return null;
    }

    _cached = weather;

    return weather;
  }

  Future<dynamic> _invokeFunction(Map<String, double> body) async {
    final WeatherFunctionInvoker? invoker = _invokeWeatherFunction;
    if (invoker != null) {
      return invoker('ootd-weather', body);
    }

    final SupabaseClient? client = _client;
    if (client == null) {
      throw StateError('WeatherRepository requires a Supabase client.');
    }

    final FunctionResponse response = await client.functions.invoke(
      'ootd-weather',
      body: body,
    );

    return response.data;
  }

  WeatherData? _parseWeatherPayload(dynamic data) {
    if (data is! Map) {
      return null;
    }

    final Map<String, dynamic> payload = Map<String, dynamic>.from(data);
    if (payload.containsKey('error')) {
      return null;
    }

    const Set<String> requiredKeys = <String>{
      'temperature',
      'feels_like',
      'min_temperature',
      'max_temperature',
      'humidity',
      'rain_probability',
      'wind_speed',
      'uv_index',
      'condition',
      'has_rain_or_snow',
      'fetched_at',
      'latitude',
      'longitude',
    };

    if (!requiredKeys.every(payload.containsKey)) {
      return null;
    }

    final bool hasUsableWeatherValue = <String>[
      'temperature',
      'feels_like',
      'min_temperature',
      'max_temperature',
      'humidity',
      'rain_probability',
      'wind_speed',
      'uv_index',
      'condition',
    ].any((String key) => payload[key] != null);

    if (!hasUsableWeatherValue) {
      return null;
    }

    return WeatherData.fromJson(payload);
  }

  bool _sameApproximateLocation(WeatherData weather, DeviceLocation location) {
    final double? cachedLat = weather.latitude;
    final double? cachedLng = weather.longitude;
    if (cachedLat == null || cachedLng == null) {
      return false;
    }

    // Refresh only after roughly 10 km of movement or cache expiry.
    return (cachedLat - location.latitude).abs() <= 0.09 &&
        (cachedLng - location.longitude).abs() <=
            0.09 / max(cos(location.latitude * pi / 180).abs(), 0.2);
  }
}
