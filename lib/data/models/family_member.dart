enum RelationshipType {
  brother,
  child,
  cousin,
  father,
  grandparent,
  mother,
  other,
  partner,
  self,
  sister;

  String get label => switch (this) {
    RelationshipType.brother => 'Brother',
    RelationshipType.child => 'Child',
    RelationshipType.cousin => 'Cousin',
    RelationshipType.father => 'Father',
    RelationshipType.grandparent => 'Grandparent',
    RelationshipType.mother => 'Mother',
    RelationshipType.other => 'Other',
    RelationshipType.partner => 'Partner',
    RelationshipType.self => 'Self',
    RelationshipType.sister => 'Sister',
  };
}

class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.name,
    required this.relationship,
    this.birthDate,
    this.currentSize,
    this.heightCm,
    this.weightKg,
    this.shoeSize,
    this.shoeUnit = 'EU',
    this.topsSize,
    this.bottomsSize,
    this.footLengthCm,
    this.avatarPath,
    this.avatarUrl,
    this.pronouns,
    this.gender,
    this.styleAesthetics = const <String>[],
    this.colorPreferences = const <String>[],
  });

  final String id;
  final String name;
  final RelationshipType relationship;
  final DateTime? birthDate;
  final String? currentSize;
  final double? heightCm;
  final double? weightKg;
  final String? shoeSize;

  /// Sizing system [shoeSize] belongs to: `EU`, `US` or `UK`.
  final String shoeUnit;

  /// Apparel size for tops. Either a child age size (`2-3Y`) or an adult
  /// letter size (`M`).
  final String? topsSize;

  /// Apparel size for bottoms. Either a child age size (`2-3Y`) or a numeric
  /// waist size (`32`).
  final String? bottomsSize;

  final double? footLengthCm;
  final String? avatarPath;
  final String? avatarUrl;
  final String? pronouns;
  final String? gender;

  /// Style aesthetics this member gravitates towards (e.g. `Casual`).
  final List<String> styleAesthetics;

  /// Preferred colour shades (e.g. `Navy`).
  final List<String> colorPreferences;

  bool get isChild => relationship == RelationshipType.child;

  /// Whether this row represents the account holder rather than a relative.
  bool get isAccount => relationship == RelationshipType.self;

  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember(
    id: json['id'] as String,
    name: json['name'] as String,
    relationship: RelationshipType.values.byName(
      json['relationship'] as String? ?? RelationshipType.self.name,
    ),
    birthDate: DateTime.tryParse(json['birth_date'] as String? ?? ''),
    currentSize: json['current_size'] as String?,
    heightCm: (json['height_cm'] as num?)?.toDouble(),
    weightKg: (json['weight_kg'] as num?)?.toDouble(),
    shoeSize: json['shoe_size'] as String?,
    shoeUnit: json['shoe_unit'] as String? ?? 'EU',
    topsSize: json['tops_size'] as String?,
    bottomsSize: json['bottoms_size'] as String?,
    footLengthCm: (json['foot_length_cm'] as num?)?.toDouble(),
    avatarPath: json['avatar_path'] as String?,
    pronouns: json['pronouns'] as String?,
    gender: json['gender'] as String?,
    styleAesthetics: _parseStringList(json['style_aesthetics']),
    colorPreferences: _parseStringList(json['color_preferences']),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'relationship': relationship.name,
    'birth_date': birthDate?.toIso8601String().split('T').first,
    'current_size': currentSize,
    'height_cm': heightCm,
    'weight_kg': weightKg,
    'shoe_size': shoeSize,
    'shoe_unit': shoeUnit,
    'tops_size': topsSize,
    'bottoms_size': bottomsSize,
    'foot_length_cm': footLengthCm,
    'avatar_path': avatarPath,
    'pronouns': pronouns,
    'gender': gender,
    'style_aesthetics': styleAesthetics,
    'color_preferences': colorPreferences,
  };

  FamilyMember copyWith({
    String? name,
    RelationshipType? relationship,
    DateTime? birthDate,
    String? currentSize,
    double? heightCm,
    double? weightKg,
    String? shoeSize,
    String? shoeUnit,
    String? topsSize,
    String? bottomsSize,
    double? footLengthCm,
    String? avatarPath,
    String? avatarUrl,
    String? pronouns,
    String? gender,
    List<String>? styleAesthetics,
    List<String>? colorPreferences,
  }) => FamilyMember(
    id: id,
    name: name ?? this.name,
    relationship: relationship ?? this.relationship,
    birthDate: birthDate ?? this.birthDate,
    currentSize: currentSize ?? this.currentSize,
    heightCm: heightCm ?? this.heightCm,
    weightKg: weightKg ?? this.weightKg,
    shoeSize: shoeSize ?? this.shoeSize,
    shoeUnit: shoeUnit ?? this.shoeUnit,
    topsSize: topsSize ?? this.topsSize,
    bottomsSize: bottomsSize ?? this.bottomsSize,
    footLengthCm: footLengthCm ?? this.footLengthCm,
    avatarPath: avatarPath ?? this.avatarPath,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    pronouns: pronouns ?? this.pronouns,
    gender: gender ?? this.gender,
    styleAesthetics: styleAesthetics ?? this.styleAesthetics,
    colorPreferences: colorPreferences ?? this.colorPreferences,
  );

  /// Reads a Postgres `text[]` column defensively, dropping blanks so a
  /// partially-migrated row cannot produce empty chips in the UI.
  static List<String> _parseStringList(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }

    return value
        .whereType<String>()
        .where((String item) => item.trim().isNotEmpty)
        .toList(growable: false);
  }
}
