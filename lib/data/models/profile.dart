class Profile {
  const Profile({
    required this.id,
    this.fullName,
    this.locationCity,
    this.countryCode,
    this.unusedAlertsEnabled = true,
    this.laundryAlertsEnabled = true,
    this.ootdAlertsEnabled = true,
    this.growthAlertsEnabled = true,
    this.deactivatedAt,
  });

  final String id;
  final String? fullName;
  final String? locationCity;

  /// ISO 3166-1 alpha-2 country code chosen during the Setup Wizard (e.g.
  /// `PK`). Null for users who onboarded before the field existed; the country
  /// → currency mapping (CountryCurrencyService) falls back to a safe default.
  final String? countryCode;

  final bool growthAlertsEnabled;
  final bool unusedAlertsEnabled;
  final bool laundryAlertsEnabled;
  final bool ootdAlertsEnabled;

  /// When non-null the account is temporarily deactivated (data preserved,
  /// reactivation allowed later). See the account-deactivation Edge Function.
  final DateTime? deactivatedAt;

  bool get isDeactivated => deactivatedAt != null;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String,
    fullName: json['full_name'] as String?,
    locationCity: json['location_city'] as String?,
    countryCode: json['country_code'] as String?,
    unusedAlertsEnabled:
    json['unused_alerts_enabled'] as bool? ?? true,
    laundryAlertsEnabled:
    json['laundry_alerts_enabled'] as bool? ?? true,
    ootdAlertsEnabled:
    json['ootd_alerts_enabled'] as bool? ?? true,
    growthAlertsEnabled:
    json['growth_alerts_enabled'] as bool? ?? true,
    deactivatedAt: _parseDateTime(json['deactivated_at']),
  );

  static DateTime? _parseDateTime(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}