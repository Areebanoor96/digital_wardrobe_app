class Profile {
  const Profile({
    required this.id,
    this.fullName,
    this.username,
    this.pronouns,
    this.gender,
    this.avatarUrl,
    this.avatarPath,
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
  final String? username;
  final String? pronouns;
  final String? gender;

  /// Public or signed image URL resolved for display UI.
  final String? avatarUrl;

  /// Raw path inside Supabase storage bucket (e.g., "user_id/avatar.jpg").
  final String? avatarPath;

  final String? locationCity;
  final String? countryCode;

  final bool growthAlertsEnabled;
  final bool unusedAlertsEnabled;
  final bool laundryAlertsEnabled;
  final bool ootdAlertsEnabled;

  final DateTime? deactivatedAt;

  bool get isDeactivated => deactivatedAt != null;

  Profile copyWith({
    String? id,
    String? fullName,
    String? username,
    String? pronouns,
    String? gender,
    String? avatarUrl,
    String? avatarPath,
    String? locationCity,
    String? countryCode,
    bool? growthAlertsEnabled,
    bool? unusedAlertsEnabled,
    bool? laundryAlertsEnabled,
    bool? ootdAlertsEnabled,
    DateTime? deactivatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      pronouns: pronouns ?? this.pronouns,
      gender: gender ?? this.gender,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarPath: avatarPath ?? this.avatarPath,
      locationCity: locationCity ?? this.locationCity,
      countryCode: countryCode ?? this.countryCode,
      growthAlertsEnabled: growthAlertsEnabled ?? this.growthAlertsEnabled,
      unusedAlertsEnabled: unusedAlertsEnabled ?? this.unusedAlertsEnabled,
      laundryAlertsEnabled: laundryAlertsEnabled ?? this.laundryAlertsEnabled,
      ootdAlertsEnabled: ootdAlertsEnabled ?? this.ootdAlertsEnabled,
      deactivatedAt: deactivatedAt ?? this.deactivatedAt,
    );
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    final rawPath = json['avatar_path'] as String?;
    final rawUrl = json['avatar_url'] as String?;

    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      username: json['username'] as String?,
      pronouns: json['pronouns'] as String?,
      gender: json['gender'] as String?,
      avatarPath: rawPath ?? rawUrl,
      avatarUrl: rawUrl ?? (rawPath != null && rawPath.startsWith('http') ? rawPath : null),
      locationCity: json['location_city'] as String?,
      countryCode: json['country_code'] as String?,
      unusedAlertsEnabled: json['unused_alerts_enabled'] as bool? ?? true,
      laundryAlertsEnabled: json['laundry_alerts_enabled'] as bool? ?? true,
      ootdAlertsEnabled: json['ootd_alerts_enabled'] as bool? ?? true,
      growthAlertsEnabled: json['growth_alerts_enabled'] as bool? ?? true,
      deactivatedAt: _parseDateTime(json['deactivated_at']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}