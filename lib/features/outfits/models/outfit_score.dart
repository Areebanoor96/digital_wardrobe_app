class OutfitScore {
  const OutfitScore({
    required this.total,
    required this.reasons,
    this.occasionScore = 0,
    this.seasonScore = 0,
    this.moodScore = 0,
    this.categoryScore = 0,
    this.colorScore = 0,
    this.freshnessScore = 0,
  });

  final int total;

  final int occasionScore;
  final int seasonScore;
  final int moodScore;
  final int categoryScore;
  final int colorScore;
  final int freshnessScore;

  final List<String> reasons;
}