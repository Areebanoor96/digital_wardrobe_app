import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/data/models/growth_measurement.dart';

class GrowthComparison {
  const GrowthComparison({
    this.heightChangeCm,
    this.weightChangeKg,
    this.clothingSizeChanged = false,
    this.shoeSizeChanged = false,
  });

  final double? heightChangeCm;
  final double? weightChangeKg;
  final bool clothingSizeChanged;
  final bool shoeSizeChanged;

  bool get hasGrowthChange =>
      (heightChangeCm != null && heightChangeCm! > 0) ||
          clothingSizeChanged ||
          shoeSizeChanged;
}

class GrowthIntelligenceService {
  const GrowthIntelligenceService();

  GrowthComparison? compare({
    required List<GrowthMeasurement> measurements,
  }) {
    if (measurements.length < 2) {
      return null;
    }

    final List<GrowthMeasurement> sorted =
    List<GrowthMeasurement>.from(measurements)
      ..sort(
            (GrowthMeasurement a, GrowthMeasurement b) =>
            b.recordedAt.compareTo(a.recordedAt),
      );

    final GrowthMeasurement latest = sorted[0];
    final GrowthMeasurement previous = sorted[1];

    return GrowthComparison(
      heightChangeCm: _difference(
        latest.heightCm,
        previous.heightCm,
      ),
      weightChangeKg: _difference(
        latest.weightKg,
        previous.weightKg,
      ),
      clothingSizeChanged: _changed(
        latest.clothingSize,
        previous.clothingSize,
      ),
      shoeSizeChanged: _changed(
        latest.shoeSize,
        previous.shoeSize,
      ),
    );
  }

  bool isEligibleForGrowthTracking(FamilyMember member) {
    if (member.relationship != RelationshipType.child) {
      return false;
    }

    final DateTime? birthDate = member.birthDate;

    if (birthDate == null) {
      return false;
    }

    return _ageInYears(birthDate) < 18;
  }

  bool needsMeasurementReminder({
    required FamilyMember member,
    required List<GrowthMeasurement> measurements,
    DateTime? now,
  }) {
    if (!isEligibleForGrowthTracking(member)) {
      return false;
    }

    if (measurements.isEmpty) {
      return true;
    }

    final List<GrowthMeasurement> sorted =
    List<GrowthMeasurement>.from(measurements)
      ..sort(
            (GrowthMeasurement a, GrowthMeasurement b) =>
            b.recordedAt.compareTo(a.recordedAt),
      );

    final DateTime today = now ?? DateTime.now();
    final GrowthMeasurement latest = sorted.first;

    return today.difference(latest.recordedAt).inDays >= 90;
  }

  int _ageInYears(DateTime birthDate) {
    final DateTime today = DateTime.now();

    int age = today.year - birthDate.year;

    final bool birthdayPassed =
        today.month > birthDate.month ||
            (today.month == birthDate.month &&
                today.day >= birthDate.day);

    if (!birthdayPassed) {
      age--;
    }

    return age;
  }

  double? _difference(double? latest, double? previous) {
    if (latest == null || previous == null) {
      return null;
    }

    return latest - previous;
  }

  bool _changed(String? latest, String? previous) {
    if (latest == null || previous == null) {
      return false;
    }

    return latest.trim().toLowerCase() !=
        previous.trim().toLowerCase();
  }
}