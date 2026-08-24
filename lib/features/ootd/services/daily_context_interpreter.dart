import 'package:digital_wardrobe_app/features/ootd/models/daily_context.dart';
import 'package:digital_wardrobe_app/features/ootd/models/daily_requirements.dart';

class DailyContextInterpreter {
  const DailyContextInterpreter();

  DailyRequirements interpret(DailyContext context) {
    final double? feelsLike = context.feelsLike ?? context.temperature;
    final double rainProbability = context.rainProbability ?? 0;
    final double humidity = context.humidity ?? 45;
    final double windSpeed = context.windSpeed ?? 0;
    final double uvIndex = context.uvIndex ?? 0;
    final bool outdoor = context.outdoor ?? false;
    final double? minTemp = context.minTemperature;
    final double? maxTemp = context.maxTemperature;

    double targetWarmth = 5.0;
    double targetBreathability = 5.0;

    if (feelsLike != null) {
      if (feelsLike >= 35) {
        targetWarmth = 1.3;
        targetBreathability = 9.5;
      } else if (feelsLike >= 30) {
        targetWarmth = 2.2;
        targetBreathability = 8.5;
      } else if (feelsLike >= 24) {
        targetWarmth = 3.6;
        targetBreathability = 7.0;
      } else if (feelsLike >= 18) {
        targetWarmth = 5.0;
        targetBreathability = 5.8;
      } else if (feelsLike >= 10) {
        targetWarmth = 7.0;
        targetBreathability = 4.5;
      } else {
        targetWarmth = 8.7;
        targetBreathability = 3.5;
      }
    }

    if (humidity >= 75 && (feelsLike ?? 24) >= 24) {
      targetBreathability += 0.8;
    }

    if (windSpeed >= 25) {
      targetWarmth += 0.5;
    }

    if (outdoor && uvIndex >= 7 && (feelsLike ?? 24) >= 24) {
      targetBreathability += 0.4;
    }

    final double rainNeed = rainProbability >= 70
        ? 8.5
        : rainProbability >= 60
        ? 7.0
        : rainProbability >= 35
        ? 4.5
        : 1.5;

    return DailyRequirements(
      targetWarmth: targetWarmth.clamp(1, 10).toDouble(),
      targetBreathability: targetBreathability.clamp(1, 10).toDouble(),
      rainProtectionNeed: rainNeed,
      targetFormality: _targetFormality(context),
      preferLightLayers:
          (feelsLike ?? 24) >= 28 || humidity >= 75 || context.indoor == true,
      preferRemovableLayer:
          windSpeed >= 25 ||
          (minTemp != null && maxTemp != null && (maxTemp - minTemp) >= 8),
      avoidSuede: rainProbability >= 60,
      avoidOpenFootwear: rainProbability >= 70 || (feelsLike ?? 20) <= 10,
      preferComfortableFootwear:
          (context.expectedActivityLevel ?? 0) >= 6 ||
          _matches(context.occasion, 'travel', 'college', 'sport'),
      avoidRestrictiveFits:
          (context.expectedActivityLevel ?? 0) >= 6 ||
          _matches(context.mood, 'relaxed', 'sporty'),
    );
  }

  double _targetFormality(DailyContext context) {
    final String? occasion = context.occasion?.toLowerCase();
    final String? dressCode = context.dressCode?.toLowerCase();

    double target = switch (occasion) {
      'sleep' => 1,
      'home' => 2,
      'sport' => 2,
      'travel' => 3,
      'casual' => 3,
      'college' => 4,
      'work' => 6,
      'party' => 6,
      'formal' => 8,
      'ethnic' => 7,
      'wedding' => 9,
      _ => 4,
    };

    if (dressCode != null) {
      if (dressCode.contains('formal')) {
        target = target < 8 ? 8 : target;
      } else if (dressCode.contains('business')) {
        target = target < 6 ? 6 : target;
      } else if (dressCode.contains('smart')) {
        target = target < 5 ? 5 : target;
      } else if (dressCode.contains('casual')) {
        target = (target - 1).clamp(1, 10).toDouble();
      }
    }

    return target;
  }

  bool _matches(String? value, String first, String second, [String? third]) {
    final String normalized = value?.toLowerCase() ?? '';
    return normalized == first ||
        normalized == second ||
        (third != null && normalized == third);
  }
}
