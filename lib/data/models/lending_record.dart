enum LendingDirection {
  lent,
  borrowed;

  String get label => switch (this) {
    LendingDirection.lent => 'Lent',
    LendingDirection.borrowed => 'Borrowed',
  };
}

class LendingRecord {
  const LendingRecord({
    required this.id,
    required this.userId,
    required this.garmentId,
    required this.direction,
    required this.personName,
    required this.dateOut,
    this.expectedReturnDate,
    this.notes,
    this.returned = false,
    this.returnedDate,
  });

  final String id;
  final String userId;
  final String garmentId;
  final LendingDirection direction;
  final String personName;
  final DateTime dateOut;
  final DateTime? expectedReturnDate;
  final String? notes;
  final bool returned;
  final DateTime? returnedDate;

  factory LendingRecord.fromJson(Map<String, dynamic> json) {
    return LendingRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      garmentId: json['garment_id'] as String,
      direction: LendingDirection.values.byName(json['direction'] as String),
      personName: json['person_name'] as String,
      dateOut: DateTime.parse(json['date_out'] as String),
      expectedReturnDate: DateTime.tryParse(
        json['expected_return_date'] as String? ?? '',
      ),
      notes: json['notes'] as String?,
      returned: json['returned'] as bool? ?? false,
      returnedDate: DateTime.tryParse(json['returned_date'] as String? ?? ''),
    );
  }
}
