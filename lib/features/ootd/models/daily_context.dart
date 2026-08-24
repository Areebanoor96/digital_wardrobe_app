import 'package:digital_wardrobe_app/features/ootd/models/weather_data.dart';
import 'package:digital_wardrobe_app/features/outfits/models/outfit_context.dart';

class DailyContext {
  const DailyContext({
    this.temperature,
    this.feelsLike,
    this.minTemperature,
    this.maxTemperature,
    this.humidity,
    this.rainProbability,
    this.windSpeed,
    this.uvIndex,
    this.weatherCondition,
    this.occasion,
    this.dressCode,
    this.mood,
    this.expectedActivityLevel,
    this.indoor,
    this.outdoor,
    required this.date,
    required this.season,
  });

  final double? temperature;
  final double? feelsLike;
  final double? minTemperature;
  final double? maxTemperature;
  final double? humidity;
  final double? rainProbability;
  final double? windSpeed;
  final double? uvIndex;
  final String? weatherCondition;
  final String? occasion;
  final String? dressCode;
  final String? mood;
  final int? expectedActivityLevel;
  final bool? indoor;
  final bool? outdoor;
  final DateTime date;
  final String season;

  factory DailyContext.from({
    WeatherData? weather,
    OutfitContext outfitContext = const OutfitContext(),
    DateTime? date,
    String? dressCode,
    int? expectedActivityLevel,
    bool? indoor,
    bool? outdoor,
  }) {
    final DateTime resolvedDate = date ?? DateTime.now();

    return DailyContext(
      temperature: weather?.temperature,
      feelsLike: weather?.feelsLike,
      minTemperature: weather?.minTemperature,
      maxTemperature: weather?.maxTemperature,
      humidity: weather?.humidity,
      rainProbability: weather?.rainProbability,
      windSpeed: weather?.windSpeed,
      uvIndex: weather?.uvIndex,
      weatherCondition: weather?.condition,
      occasion: outfitContext.occasion,
      dressCode: dressCode,
      mood: outfitContext.mood,
      expectedActivityLevel: expectedActivityLevel,
      indoor: indoor,
      outdoor: outdoor,
      date: resolvedDate,
      season: outfitContext.season ?? inferSeason(resolvedDate, weather),
    );
  }

  static String inferSeason(DateTime date, WeatherData? weather) {
    final double? temp = weather?.feelsLike ?? weather?.temperature;
    final double? rain = weather?.rainProbability;

    if ((rain ?? 0) >= 60 ||
        (weather?.condition ?? '').toLowerCase().contains('rain')) {
      return 'rainy';
    }

    if (temp != null) {
      if (temp >= 28) {
        return 'summer';
      }
      if (temp <= 14) {
        return 'winter';
      }
    }

    return switch (date.month) {
      12 || 1 || 2 => 'winter',
      3 || 4 => 'spring',
      5 || 6 || 7 || 8 || 9 => 'summer',
      _ => 'autumn',
    };
  }
}
