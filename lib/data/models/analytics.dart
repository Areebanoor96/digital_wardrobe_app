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
}
