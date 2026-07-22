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
}

class Alert {
  const Alert({
    required this.id,
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
    userId: json['user_id'] as String,
    type: AlertType.values.byName(json['type'] as String),
    garmentId: json['garment_id'] as String?,
    title: json['title'] as String,
    body: json['body'] as String?,
    isRead: json['is_read'] as bool? ?? false,
    isDismissed: json['is_dismissed'] as bool? ?? false,
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
  );
}
