import 'dart:math';

import 'package:digital_wardrobe_app/features/ootd/models/weather_data.dart';
import 'package:digital_wardrobe_app/features/ootd/services/location_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef WeatherFunctionInvoker =
    Future<dynamic> Function(String functionName, Map<String, dynamic> body);

class WeatherRepository {
  WeatherRepository(this._client) : _invokeWeatherFunction = null;

  WeatherRepository.forTesting(this._invokeWeatherFunction) : _client = null;

  final SupabaseClient? _client;
  final WeatherFunctionInvoker? _invokeWeatherFunction;
  WeatherData? _cached;
  final Map<String, WeatherData> _dateCache = <String, WeatherData>{};

  /// Fetches weather for the current moment when [forDate] is null (unchanged
  /// from existing behaviour). When [forDate] is non-null, fetches a forecast
  /// summary for that specific local calendar date. Each target date is cached
  /// separately so a future date is never confused with today's weather.
  Future<WeatherData?> fetchForLocation({
    required DeviceLocation location,
    bool forceRefresh = false,
    DateTime? forDate,
  }) async {
    if (forDate == null) {
      return _fetchToday(location: location, forceRefresh: forceRefresh);
    }
    return _fetchForDate(
      location: location,
      forDate: forDate,
      forceRefresh: forceRefresh,
    );
  }

  Future<WeatherData?> _fetchToday({
    required DeviceLocation location,
    required bool forceRefresh,
  }) async {
    final WeatherData? cached = _cached;
    if (!forceRefresh &&
        cached != null &&
        !cached.isStale &&
        _sameApproximateLocation(cached, location)) {
      return cached;
    }

    final Map<String, dynamic> body = <String, dynamic>{
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

  Future<WeatherData?> _fetchForDate({
    required DeviceLocation location,
    required DateTime forDate,
    required bool forceRefresh,
  }) async {
    final DateTime day = DateTime(forDate.year, forDate.month, forDate.day);
    final String key = _dateKey(day);

    final WeatherData? cached = _dateCache[key];
    if (cached != null &&
        !forceRefresh &&
        !cached.isStale &&
        _sameApproximateLocation(cached, location)) {
      return cached;
    }

    final Map<String, dynamic> body = <String, dynamic>{
      'latitude': location.latitude,
      'longitude': location.longitude,
      'target_date': key,
    };

    final dynamic data = await _invokeFunction(body);
    final WeatherData? weather = _parseWeatherPayload(data);
    if (weather == null) {
      return null;
    }

    _dateCache[key] = weather;

    return weather;
  }

  Future<dynamic> _invokeFunction(Map<String, dynamic> body) async {
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

    // An `available: false` payload signals the requested date lies outside
    // the forecast window. Return a usable WeatherData so the caller can
    // distinguish "out of forecast range" from a genuine failure.
    if (payload['available'] == false) {
      return WeatherData.fromJson(payload);
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

  static String _dateKey(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
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
