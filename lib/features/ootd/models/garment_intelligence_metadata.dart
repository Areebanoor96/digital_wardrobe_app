class GarmentIntelligenceMetadata {
  const GarmentIntelligenceMetadata({
    required this.formality,
    required this.warmth,
    required this.breathability,
    required this.visualIntensity,
    required this.versatility,
    required this.statementLevel,
  });

  /// Internal normalized values are kept on a 1-10 scale.
  final double formality;
  final double warmth;
  final double breathability;
  final double visualIntensity;
  final double versatility;
  final double statementLevel;
}
