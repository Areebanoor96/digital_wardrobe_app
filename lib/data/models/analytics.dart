class AnalyticsSummary {
  const AnalyticsSummary({
    required this.totalGarments,
    required this.activeGarments,
    required this.archivedGarments,
    required this.totalWears,
    this.totalValue,
    this.mostWornName,
    this.mostWornCount,
    this.leastWornName,
    this.leastWornCount,
    this.categoryDistribution = const <String, int>{},
    this.wearDistribution = const <String, int>{},
  });

  final int totalGarments;
  final int activeGarments;
  final int archivedGarments;
  final int totalWears;
  final double? totalValue;
  final String? mostWornName;
  final int? mostWornCount;
  final String? leastWornName;
  final int? leastWornCount;

  /// Category label → count of active garments.
  final Map<String, int> categoryDistribution;

  /// Wear-label → count of garments with that wear range.
  final Map<String, int> wearDistribution;
}
