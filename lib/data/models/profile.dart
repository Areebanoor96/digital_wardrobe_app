class Profile {
  const Profile({required this.id, this.fullName, this.locationCity});

  final String id;
  final String? fullName;
  final String? locationCity;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String,
    fullName: json['full_name'] as String?,
    locationCity: json['location_city'] as String?,
  );
}
