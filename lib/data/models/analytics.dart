class AnalyticsSummary {
  const AnalyticsSummary({
    required this.totalGarments,
    required this.activeGarments,
    required this.archivedGarments,
    required this.totalWears,
    this.totalValue,
    this.averageCostPerWear,
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
  final double? averageCostPerWear;
  final String? mostWornName;
  final int? mostWornCount;
  final String? leastWornName;
  final int? leastWornCount;
}

class CostPerWearEntry {
  const CostPerWearEntry({
    required this.garmentId,
    required this.name,
    required this.price,
    required this.wearCount,
    required this.costPerWear,
  });

  final String garmentId;
  final String name;
  final double price;
  final int wearCount;
  final double costPerWear;

  factory CostPerWearEntry.fromJson(Map<String, dynamic> json) =>
      CostPerWearEntry(
        garmentId: json['id'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        wearCount: json['wear_count'] as int,
        costPerWear: (json['cost_per_wear'] as num).toDouble(),
      );
}
