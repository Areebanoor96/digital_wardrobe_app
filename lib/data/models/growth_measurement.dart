class GrowthMeasurement {
  const GrowthMeasurement({
    required this.id,
    required this.memberId,
    required this.recordedAt,
    this.heightCm,
    this.weightKg,
    this.clothingSize,
    this.shoeSize,
    this.footLengthCm,
  });

  final String id;
  final String memberId;
  final DateTime recordedAt;

  final double? heightCm;
  final double? weightKg;
  final String? clothingSize;
  final String? shoeSize;
  final double? footLengthCm;

  factory GrowthMeasurement.fromJson(Map<String, dynamic> json) =>
      GrowthMeasurement(
        id: json['id'] as String,
        memberId: json['member_id'] as String,
        recordedAt: DateTime.parse(json['recorded_at'] as String),
        heightCm: (json['height_cm'] as num?)?.toDouble(),
        weightKg: (json['weight_kg'] as num?)?.toDouble(),
        clothingSize: json['clothing_size'] as String?,
        shoeSize: json['shoe_size'] as String?,
        footLengthCm: (json['foot_length_cm'] as num?)?.toDouble(),
      );
}
