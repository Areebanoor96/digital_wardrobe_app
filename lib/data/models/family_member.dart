enum RelationshipType {
  self,
  mother,
  father,
  brother,
  sister,
  partner,
  child,
  grandparent,
  cousin,
  other;

  String get label => switch (this) {
    RelationshipType.self => 'Self',
    RelationshipType.mother => 'Mother',
    RelationshipType.father => 'Father',
    RelationshipType.brother => 'Brother',
    RelationshipType.sister => 'Sister',
    RelationshipType.partner => 'Partner',
    RelationshipType.child => 'Child',
    RelationshipType.grandparent => 'Grandparent',
    RelationshipType.cousin => 'Cousin',
    RelationshipType.other => 'Other',
  };
}

class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.name,
    required this.relationship,
    this.birthDate,
    this.currentSize,
    this.avatarPath,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final RelationshipType relationship;
  final DateTime? birthDate;
  final String? currentSize;
  final String? avatarPath;
  final String? avatarUrl;

  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember(
    id: json['id'] as String,
    name: json['name'] as String,
    relationship: RelationshipType.values.byName(
      json['relationship'] as String? ?? RelationshipType.self.name,
    ),
    birthDate: DateTime.tryParse(json['birth_date'] as String? ?? ''),
    currentSize: json['current_size'] as String?,
    avatarPath: json['avatar_path'] as String?,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'relationship': relationship.name,
    'birth_date': birthDate?.toIso8601String().split('T').first,
    'current_size': currentSize,
    'avatar_path': avatarPath,
  };

  FamilyMember copyWith({
    String? name,
    RelationshipType? relationship,
    DateTime? birthDate,
    String? currentSize,
    String? avatarPath,
    String? avatarUrl,
  }) => FamilyMember(
    id: id,
    name: name ?? this.name,
    relationship: relationship ?? this.relationship,
    birthDate: birthDate ?? this.birthDate,
    currentSize: currentSize ?? this.currentSize,
    avatarPath: avatarPath ?? this.avatarPath,
    avatarUrl: avatarUrl ?? this.avatarUrl,
  );
}
