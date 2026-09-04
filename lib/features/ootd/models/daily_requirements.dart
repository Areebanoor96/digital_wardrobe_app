class DailyRequirements {
  const DailyRequirements({
    required this.targetWarmth,
    required this.targetBreathability,
    required this.rainProtectionNeed,
    required this.windProtectionNeed,
    required this.targetFormality,
    required this.preferLightLayers,
    required this.preferRemovableLayer,
    required this.avoidSuede,
    required this.avoidOpenFootwear,
    required this.preferComfortableFootwear,
    required this.avoidRestrictiveFits,
    this.preferredFabrics = const <String>[],
    this.avoidedFabrics = const <String>[],
  });

  final double targetWarmth;
  final double targetBreathability;
  final double rainProtectionNeed;
  final double windProtectionNeed;
  final double targetFormality;
  final bool preferLightLayers;
  final bool preferRemovableLayer;
  final bool avoidSuede;
  final bool avoidOpenFootwear;
  final bool preferComfortableFootwear;
  final bool avoidRestrictiveFits;
  final List<String> preferredFabrics;
  final List<String> avoidedFabrics;
}
