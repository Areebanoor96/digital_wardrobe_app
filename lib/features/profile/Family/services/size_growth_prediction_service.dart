import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/growth_measurement.dart';

/// Monotonic rank for the child garment sizes defined on the garment form.
/// Ranks order the labels by the upper age bound they represent; adult sizes
/// sit above all child sizes so teens who have moved to adult fits still rank.
const Map<String, int> _childClothingSizeRanks = <String, int>{
  '0-1M': 1,
  '1-3M': 2,
  '3-6M': 3,
  '6-9M': 4,
  '9-12M': 5,
  '12-18M': 6,
  '18-24M': 7,
  '2-3Y': 8,
  '3-4Y': 9,
  '4-5Y': 10,
  '5-6Y': 11,
  '6-7Y': 12,
  '7-8Y': 13,
  '8-9Y': 14,
  '9-10Y': 15,
  '10-11Y': 16,
  '11-12Y': 17,
  '12-13Y': 18,
  '13-14Y': 19,
  'XS': 20,
  'S': 21,
  'M': 22,
  'L': 23,
  'XL': 24,
  'XXL': 25,
  '3XL': 26,
};

/// Result of a size-growth prediction for a single garment.
class SizeGrowthPrediction {
  const SizeGrowthPrediction({
    required this.garmentId,
    required this.garmentName,
    required this.garmentSize,
    required this.estimatedOutgrowthDate,
  });

  final String garmentId;
  final String garmentName;
  final String garmentSize;
  final DateTime estimatedOutgrowthDate;

  /// e.g. "October" for the month the garment is expected to stop fitting.
  String get estimatedOutgrowthMonth {
    return _monthNames[estimatedOutgrowthDate.month - 1];
  }

  static const List<String> _monthNames = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
}

/// Predicts whether a child's garment will be outgrown within a lead time by
/// comparing the garment's size against the child's current size (from the
/// latest growth measurement or the member record) and the child's expected
/// growth rate based on their age and current height.
class SizeGrowthPredictionService {
  const SizeGrowthPredictionService({this.leadTimeMonths = 3});

  /// How far ahead (months) the prediction looks, e.g. 3 months.
  final int leadTimeMonths;

  /// Returns a prediction when the [garment] is expected to become too small
  /// within [leadTimeMonths], otherwise `null`.
  SizeGrowthPrediction? predict({
    required FamilyMember member,
    required Garment garment,
    List<GrowthMeasurement> measurements = const <GrowthMeasurement>[],
    DateTime? now,
  }) {
    final DateTime today = now ?? DateTime.now();

    if (!_isSizeBearingGarment(garment)) {
      return null;
    }

    if (member.relationship != RelationshipType.child) {
      return null;
    }

    final DateTime? birthDate = member.birthDate;

    if (birthDate == null) {
      return null;
    }

    final int ageMonths = _ageInWholeMonths(birthDate, today);

    final bool isShoe = garment.category == GarmentCategory.shoe;

    final int? garmentRank = _rankOf(garment.size, isShoe: isShoe);

    if (garmentRank == null) {
      return null;
    }

    final String? currentSize = _currentSizeOf(
      member: member,
      measurements: measurements,
      isShoe: isShoe,
    );

    final int? currentRank = _rankOf(currentSize, isShoe: isShoe);

    if (currentRank == null) {
      return null;
    }

    // The garment is already smaller than the child's current size — it has
    // already been outgrown rather than being predicted to outgrow.
    if (garmentRank < currentRank) {
      return null;
    }

    final int monthsPerSizeStep = _monthsPerSizeStep(ageMonths);

    // A garment that matches the child's current size is expected to stop
    // fitting after a single growth step.
    final int monthsRemaining = garmentRank == currentRank
        ? monthsPerSizeStep
        : (garmentRank - currentRank) * monthsPerSizeStep;

    if (monthsRemaining > leadTimeMonths) {
      return null;
    }

    return SizeGrowthPrediction(
      garmentId: garment.id,
      garmentName: garment.name,
      garmentSize: garment.size!,
      estimatedOutgrowthDate: _addCalendarMonths(today, monthsRemaining),
    );
  }

  /// Categories which carry a size the way the garment form models them.
  bool _isSizeBearingGarment(Garment garment) {
    return switch (garment.category) {
      GarmentCategory.top ||
      GarmentCategory.bottom ||
      GarmentCategory.dress ||
      GarmentCategory.outerwear ||
      GarmentCategory.shoe => true,
      _ => false,
    };
  }

  /// The child's most recent logged size for the garment type, preferring the
  /// latest growth measurement and falling back to the member record.
  String? _currentSizeOf({
    required FamilyMember member,
    required List<GrowthMeasurement> measurements,
    required bool isShoe,
  }) {
    GrowthMeasurement? latest;

    for (final GrowthMeasurement measurement in measurements) {
      if (latest == null ||
          measurement.recordedAt.isAfter(latest.recordedAt)) {
        latest = measurement;
      }
    }

    if (isShoe) {
      return (latest != null && latest.shoeSize != null)
          ? latest.shoeSize
          : member.shoeSize;
    }

    return (latest != null && latest.clothingSize != null)
        ? latest.clothingSize
        : member.currentSize;
  }

  int? _rankOf(String? size, {required bool isShoe}) {
    final String cleaned = size?.trim() ?? '';

    if (cleaned.isEmpty) {
      return null;
    }

    if (isShoe) {
      final int? numeric = int.tryParse(cleaned);

      if (numeric == null || numeric < 20 || numeric > 60) {
        return null;
      }

      return numeric;
    }

    return _childClothingSizeRanks[cleaned];
  }

  /// Average months a child spends in one clothing size step, by age.
  int _monthsPerSizeStep(int ageMonths) {
    if (ageMonths < 24) {
      return 3;
    }
    if (ageMonths < 72) {
      return 6;
    }
    if (ageMonths < 144) {
      return 12;
    }

    return 18;
  }

  int _ageInWholeMonths(DateTime birthDate, DateTime today) {
    int months =
        (today.year - birthDate.year) * 12 + (today.month - birthDate.month);

    if (today.day < birthDate.day) {
      months--;
    }

    return months;
  }

  DateTime _addCalendarMonths(DateTime date, int months) {
    final DateTime source = DateTime(date.year, date.month, date.day);
    final int targetMonthIndex = source.month - 1 + months;
    final int year = source.year + targetMonthIndex ~/ 12;
    final int month = targetMonthIndex % 12 + 1;
    final int lastDay = DateTime(year, month + 1, 0).day;

    return DateTime(
      year,
      month,
      source.day.clamp(1, lastDay).toInt(),
    );
  }
}