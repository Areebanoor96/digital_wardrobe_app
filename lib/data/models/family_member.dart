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
    this.footLengthCm,
    this.avatarPath,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final RelationshipType relationship;
  final DateTime? birthDate;
  final String? currentSize;
  final double? heightCm;
  final double? weightKg;
  final String? shoeSize;
  final double? footLengthCm;
  final String? avatarPath;
  final String? avatarUrl;

  bool get isChild => relationship == RelationshipType.child;

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
    footLengthCm: (json['foot_length_cm'] as num?)?.toDouble(),
    avatarPath: json['avatar_path'] as String?,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'relationship': relationship.name,
    'birth_date': birthDate?.toIso8601String().split('T').first,
    'current_size': currentSize,
    'height_cm': heightCm,
    'weight_kg': weightKg,
    'shoe_size': shoeSize,
    'foot_length_cm': footLengthCm,
    'avatar_path': avatarPath,
  };

  FamilyMember copyWith({
    String? name,
    RelationshipType? relationship,
    DateTime? birthDate,
    String? currentSize,
    double? heightCm,
    double? weightKg,
    String? shoeSize,
    double? footLengthCm,
    String? avatarPath,
    String? avatarUrl,
  }) => FamilyMember(
    id: id,
    name: name ?? this.name,
    relationship: relationship ?? this.relationship,
    birthDate: birthDate ?? this.birthDate,
    currentSize: currentSize ?? this.currentSize,
    heightCm: heightCm ?? this.heightCm,
    weightKg: weightKg ?? this.weightKg,
    shoeSize: shoeSize ?? this.shoeSize,
    footLengthCm: footLengthCm ?? this.footLengthCm,
    avatarPath: avatarPath ?? this.avatarPath,
    avatarUrl: avatarUrl ?? this.avatarUrl,
  );
}
