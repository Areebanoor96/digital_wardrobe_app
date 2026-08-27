class GarmentLocation {
  const GarmentLocation({
    required this.id,
    required this.userId,
    required this.memberId,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String memberId;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory GarmentLocation.fromJson(Map<String, dynamic> json) {
    return GarmentLocation(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      memberId: json['member_id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }
}
