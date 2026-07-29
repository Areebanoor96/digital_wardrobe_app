import 'package:digital_wardrobe_app/data/models/garment.dart';

class WearLog {
  const WearLog({
    required this.id,
    required this.memberId,
    required this.garmentId,
    required this.wornDate,
    this.outfitId,
    this.eventName,
    this.notes,
    this.laundryStatusAfter,
  });

  final String id;
  final String memberId;
  final String garmentId;
  final DateTime wornDate;
  final String? outfitId;

  /// Examples: University, Office, Wedding, Dinner or Travel.
  final String? eventName;

  final String? notes;
  final LaundryStatus? laundryStatusAfter;

  factory WearLog.fromJson(Map<String, dynamic> json) {
    final String? laundryStatusValue =
    json['laundry_status_after'] as String?;

    return WearLog(
      id: json['id'] as String,
      memberId: json['member_id'] as String,
      garmentId: json['garment_id'] as String,
      wornDate: DateTime.parse(json['worn_date'] as String),
      outfitId: json['outfit_id'] as String?,
      eventName: json['event_name'] as String?,
      notes: json['notes'] as String?,
      laundryStatusAfter: laundryStatusValue == null
          ? null
          : LaundryStatus.values.byName(laundryStatusValue),
    );
  }
}