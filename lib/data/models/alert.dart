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

class AlertTargetTypes {
  const AlertTargetTypes._();

  static const String garment = 'garment';
  static const String familyMember = 'family_member';
  static const String ootdRecommendation = 'ootd_recommendation';
  static const String outfit = 'outfit';
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
    this.targetType,
    this.targetId,
    this.actionPayload = const <String, dynamic>{},
    this.readAt,
    this.dismissedAt,
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
  final String? targetType;
  final String? targetId;
  final Map<String, dynamic> actionPayload;
  final DateTime? readAt;
  final DateTime? dismissedAt;
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
    targetType: json['target_type'] as String?,
    targetId: json['target_id'] as String?,
    actionPayload: _payloadFromJson(json['action_payload']),
    readAt: DateTime.tryParse(json['read_at'] as String? ?? ''),
    dismissedAt: DateTime.tryParse(json['dismissed_at'] as String? ?? ''),
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
  );

  Alert copyWith({
    bool? isRead,
    bool? isDismissed,
    DateTime? readAt,
    DateTime? dismissedAt,
  }) {
    return Alert(
      id: id,
      memberId: memberId,
      userId: userId,
      type: type,
      garmentId: garmentId,
      title: title,
      body: body,
      isRead: isRead ?? this.isRead,
      isDismissed: isDismissed ?? this.isDismissed,
      targetType: targetType,
      targetId: targetId,
      actionPayload: actionPayload,
      readAt: readAt ?? this.readAt,
      dismissedAt: dismissedAt ?? this.dismissedAt,
      createdAt: createdAt,
    );
  }
}

Map<String, dynamic> _payloadFromJson(dynamic value) {
  if (value is! Map) {
    return const <String, dynamic>{};
  }

  return Map<String, dynamic>.from(value);
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
