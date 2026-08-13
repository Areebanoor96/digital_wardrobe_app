class Profile {
  const Profile({
    required this.id,
    this.fullName,
    this.locationCity,
    this.unusedAlertsEnabled = true,
    this.laundryAlertsEnabled = true,
    this.ootdAlertsEnabled = true,
    this.growthAlertsEnabled = true,
  });

  final String id;
  final String? fullName;
  final String? locationCity;
  final bool growthAlertsEnabled;
  final bool unusedAlertsEnabled;
  final bool laundryAlertsEnabled;
  final bool ootdAlertsEnabled;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String,
    fullName: json['full_name'] as String?,
    locationCity: json['location_city'] as String?,
    unusedAlertsEnabled:
    json['unused_alerts_enabled'] as bool? ?? true,
    laundryAlertsEnabled:
    json['laundry_alerts_enabled'] as bool? ?? true,
    ootdAlertsEnabled:
    json['ootd_alerts_enabled'] as bool? ?? true,
    growthAlertsEnabled:
    json['growth_alerts_enabled'] as bool? ?? true,
  );
}