class Outfit {
  const Outfit({
    required this.id,
    required this.garmentIds,
    required this.memberId,
    this.name,
    this.occasion,
    this.coverPhotoUrl,
    this.createdAt,
    this.lastWornDate,
    this.timesWorn = 0,
  });

  final String id;
  final String? name;
  final String memberId;
  final List<String> garmentIds;
  final String? occasion;
  final String? coverPhotoUrl;
  final DateTime? createdAt;
  final DateTime? lastWornDate;
  final int timesWorn;

  factory Outfit.fromJson(Map<String, dynamic> json) => Outfit(
    id: json['id'] as String,
    memberId: json['member_id'] as String,
    name: json['name'] as String?,
    garmentIds: List<String>.from(json['garment_ids'] as List<dynamic>),
    occasion: json['occasion'] as String?,
    coverPhotoUrl: json['cover_photo_url'] as String?,
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    lastWornDate: DateTime.tryParse(json['last_worn_date'] as String? ?? ''),
    timesWorn: json['times_worn'] as int? ?? 0,
  );

  Outfit copyWith({
    DateTime? lastWornDate,
    int? timesWorn,
    String? coverPhotoUrl,
  }) => Outfit(
    id: id,
    garmentIds: garmentIds,
    memberId: memberId,
    name: name,
    occasion: occasion,
    coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
    createdAt: createdAt,
    lastWornDate: lastWornDate ?? this.lastWornDate,
    timesWorn: timesWorn ?? this.timesWorn,
  );
}
