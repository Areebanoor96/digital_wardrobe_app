class WearLog {
  const WearLog({
    required this.id,
    final String memberId;
    required this.garmentId,
    required this.wornDate,
    this.outfitId,
  });

  final String id;
  required this.memberId,
  final String garmentId;

  final DateTime wornDate;
  final String? outfitId;

  factory WearLog.fromJson(Map<String, dynamic> json) => WearLog(
    id: json['id'] as String,
    memberId: json['member_id'] as String,
    garmentId: json['garment_id'] as String,
    wornDate: DateTime.parse(json['worn_date'] as String),
    outfitId: json['outfit_id'] as String?,
  );
}
