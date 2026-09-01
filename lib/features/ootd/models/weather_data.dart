class WeatherData {
  const WeatherData({
    this.temperature,
    this.feelsLike,
    this.minTemperature,
    this.maxTemperature,
    this.humidity,
    this.rainProbability,
    this.windSpeed,
    this.uvIndex,
    this.condition,
    this.hasRainOrSnow = false,
    this.available = true,
    this.fetchedAt,
    this.latitude,
    this.longitude,
  });

  final double? temperature;
  final double? feelsLike;
  final double? minTemperature;
  final double? maxTemperature;
  final double? humidity;
  final double? rainProbability;
  final double? windSpeed;
  final double? uvIndex;
  final String? condition;
  final bool hasRainOrSnow;

  /// Whether a usable weather reading truly exists for the requested context.
  /// `false` indicates the requested date is outside the available forecast
  /// window (no weather was invented for it).
  final bool available;

  final DateTime? fetchedAt;
  final double? latitude;
  final double? longitude;

  static const Duration cacheTtl = Duration(hours: 2);

  bool get isStale {
    final DateTime? fetched = fetchedAt;
    if (fetched == null) {
      return true;
    }

    return DateTime.now().difference(fetched) >= cacheTtl;
  }

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: _toDouble(json['temperature']),
      feelsLike: _toDouble(json['feels_like'] ?? json['feelsLike']),
      minTemperature: _toDouble(
        json['min_temperature'] ?? json['minTemperature'],
      ),
      maxTemperature: _toDouble(
        json['max_temperature'] ?? json['maxTemperature'],
      ),
      humidity: _toDouble(json['humidity']),
      rainProbability: _normalizeProbability(
        json['rain_probability'] ?? json['rainProbability'],
      ),
      windSpeed: _toDouble(json['wind_speed'] ?? json['windSpeed']),
      uvIndex: _toDouble(json['uv_index'] ?? json['uvIndex']),
      condition: json['condition'] as String?,
      hasRainOrSnow:
          (json['has_rain_or_snow'] as bool?) ??
          (json['hasRainOrSnow'] as bool?) ??
          false,
      available: (json['available'] as bool?) ?? true,
      fetchedAt: DateTime.tryParse(json['fetched_at'] as String? ?? ''),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
    );
  }

  static double? _toDouble(dynamic value) {
    return (value as num?)?.toDouble();
  }

  static double? _normalizeProbability(dynamic value) {
    final double? parsed = _toDouble(value);
    if (parsed == null) {
      return null;
    }

    return parsed <= 1 ? parsed * 100 : parsed;
  }
}
