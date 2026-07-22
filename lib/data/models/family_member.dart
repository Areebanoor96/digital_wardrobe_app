enum RelationshipType {
  self,
  child,
  partner,
  other;

  String get label => switch (this) {
    RelationshipType.self => 'Self',
    RelationshipType.child => 'Child',
    RelationshipType.partner => 'Partner',
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
    this.avatarUrl,
  });

  final String id;
  final String name;
  final RelationshipType relationship;
  final DateTime? birthDate;
  final String? currentSize;
  final String? avatarUrl;

  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember(
    id: json['id'] as String,
    name: json['name'] as String,
    relationship: RelationshipType.values.byName(
      json['relationship'] as String? ?? RelationshipType.self.name,
    ),
    birthDate: DateTime.tryParse(json['birth_date'] as String? ?? ''),
    currentSize: json['current_size'] as String?,
    avatarUrl: json['avatar_url'] as String?,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'relationship': relationship.name,
    'birth_date': birthDate?.toIso8601String().split('T').first,
    'current_size': currentSize,
    'avatar_url': avatarUrl,
  };

  FamilyMember copyWith({
    String? name,
    RelationshipType? relationship,
    DateTime? birthDate,
    String? currentSize,
    String? avatarUrl,
  }) => FamilyMember(
    id: id,
    name: name ?? this.name,
    relationship: relationship ?? this.relationship,
    birthDate: birthDate ?? this.birthDate,
    currentSize: currentSize ?? this.currentSize,
    avatarUrl: avatarUrl ?? this.avatarUrl,
  );
}