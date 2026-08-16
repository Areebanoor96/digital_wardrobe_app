enum AlertType {
  unused,
  laundry,
  ootd,
  growth,
  lendReturn,
  handMeDown,
  expiry,
  sale;

  String get label => switch (this) {
    AlertType.unused => 'Unused',
    AlertType.laundry => 'Laundry',
    AlertType.ootd => 'Outfit Suggestion',
    AlertType.growth => 'Growth',
    AlertType.lendReturn => 'Lend / Return',
    AlertType.handMeDown => 'Hand-me-down',
    AlertType.expiry => 'Expiry',
    AlertType.sale => 'Sale',
  };
  String get dbValue => switch (this) {
    AlertType.unused => 'unused',
    AlertType.laundry => 'laundry',
    AlertType.ootd => 'ootd',
    AlertType.growth => 'growth',
    AlertType.lendReturn => 'lend_return',
    AlertType.handMeDown => 'hand_me_down',
    AlertType.expiry => 'expiry',
    AlertType.sale => 'sale',
  };
}

class Alert {
  const Alert({
    required this.id,
    required this.memberId,
    required this.userId,
    required this.type,
    this.garmentId,
    required this.title,
    this.body,
    this.isRead = false,
    this.isDismissed = false,
    this.createdAt,
  });

  final String id;
  final String memberId;
  final String userId;
  final AlertType type;
  final String? garmentId;
  final String title;
  final String? body;
  final bool isRead;
  final bool isDismissed;
  final DateTime? createdAt;

  factory Alert.fromJson(Map<String, dynamic> json) => Alert(
    id: json['id'] as String,
    memberId: json['member_id'] as String,
    userId: json['user_id'] as String,
    type: _alertTypeFromJson(json['type'] as String),
    garmentId: json['garment_id'] as String?,
    title: json['title'] as String,
    body: json['body'] as String?,
    isRead: json['is_read'] as bool? ?? false,
    isDismissed: json['is_dismissed'] as bool? ?? false,
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
  );
}
AlertType _alertTypeFromJson(String value) {
  return switch (value) {
    'unused' => AlertType.unused,
    'laundry' => AlertType.laundry,
    'ootd' => AlertType.ootd,
    'growth' => AlertType.growth,
    'lend_return' => AlertType.lendReturn,
    'hand_me_down' => AlertType.handMeDown,
    'expiry' => AlertType.expiry,
    'sale' => AlertType.sale,
    _ => throw ArgumentError('Unknown alert type: $value'),
  };
}
