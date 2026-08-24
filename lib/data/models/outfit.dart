class Outfit {
  const Outfit({
    required this.id,
    required this.garmentIds,
    required this.memberId,
    this.name,
    this.mood,
    this.occasion,
    this.season,
    this.isFavorite = false,
    this.coverPhotoUrl,
    this.createdAt,
    this.lastWornDate,
    this.timesWorn = 0,
  });

  final String id;
  final String? name;
  final String memberId;
  final List<String> garmentIds;
  final String? mood;
  final String? occasion;
  final String? season;
  final bool isFavorite;
  final String? coverPhotoUrl;
  final DateTime? createdAt;
  final DateTime? lastWornDate;
  final int timesWorn;

  factory Outfit.fromJson(Map<String, dynamic> json) => Outfit(
    id: json['id'] as String,
    memberId: json['member_id'] as String,
    name: json['name'] as String?,
    garmentIds: List<String>.from(json['garment_ids'] as List<dynamic>),
    mood: json['mood'] as String?,
    occasion: json['occasion'] as String?,
    season: json['season'] as String?,
    isFavorite: json['is_favorite'] as bool? ?? false,
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
    mood: mood,
    occasion: occasion,
    season: season,
    isFavorite: isFavorite,
    coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
    createdAt: createdAt,
    lastWornDate: lastWornDate ?? this.lastWornDate,
    timesWorn: timesWorn ?? this.timesWorn,
  );
}
