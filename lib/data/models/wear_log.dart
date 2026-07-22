class WearLog {
  const WearLog({
    required this.id,
    required this.garmentId,
    required this.wornDate,
    this.outfitId,
  });

  final String id;
  final String garmentId;
  final DateTime wornDate;
  final String? outfitId;

  factory WearLog.fromJson(Map<String, dynamic> json) => WearLog(
    id: json['id'] as String,
    garmentId: json['garment_id'] as String,
    wornDate: DateTime.parse(json['worn_date'] as String),
    outfitId: json['outfit_id'] as String?,
  );
}
