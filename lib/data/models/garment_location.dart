/// Thrown when creating or renaming a location that already exists for the
/// same profile (case and whitespace insensitive, mirroring the database
/// unique index on `(member_id, lower(trim(name)))`).
class LocationNameConflict implements Exception {
  const LocationNameConflict(String name) : message = 'A location named "$name" already exists.';

  final String message;

  @override
  String toString() => message;
}

/// Returns true when [name] already exists in [locations] (ignoring case and
/// leading/trailing whitespace), excluding [exceptId] so a rename to itself is
/// not treated as a conflict.
bool hasDuplicateLocationName(
  List<GarmentLocation> locations,
  String name, {
  String? exceptId,
}) {
  final String normalized = name.trim().toLowerCase();
  if (normalized.isEmpty) {
    return false;
  }

  for (final GarmentLocation location in locations) {
    if (location.id == exceptId) {
      continue;
    }
    if (location.name.trim().toLowerCase() == normalized) {
      return true;
    }
  }

  return false;
}

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
