import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/ootd/models/daily_requirements.dart';
import 'package:digital_wardrobe_app/features/ootd/models/outfit_candidate.dart';
import 'package:digital_wardrobe_app/features/ootd/services/garment_metadata_interpreter.dart';

class HardRuleResult {
  const HardRuleResult.accepted() : accepted = true, reason = null;

  const HardRuleResult.rejected(this.reason) : accepted = false;

  final bool accepted;
  final String? reason;
}

class HardRuleEngine {
  const HardRuleEngine({
    this.metadataInterpreter = const GarmentMetadataInterpreter(),
  });

  final GarmentMetadataInterpreter metadataInterpreter;

  HardRuleResult evaluate({
    required OutfitCandidate candidate,
    required DailyRequirements requirements,
    String? memberId,
  }) {
    if (candidate.garments.isEmpty) {
      return const HardRuleResult.rejected('candidate is empty');
    }

    final Set<String> ids = <String>{};
    for (final Garment garment in candidate.garments) {
      if (!ids.add(garment.id)) {
        return const HardRuleResult.rejected('duplicate garment');
      }

      if (garment.isArchived) {
        return const HardRuleResult.rejected('archived garment');
      }

      if (garment.laundryStatus != LaundryStatus.clean) {
        return const HardRuleResult.rejected('unavailable laundry state');
      }

      if (!garment.availabilityStatus.isPhysicallyAvailable) {
        return const HardRuleResult.rejected('unavailable garment status');
      }

      if (garment.ironingStatus == IroningStatus.needsIroning) {
        return const HardRuleResult.rejected('needs ironing');
      }

      if (memberId != null && garment.memberId != memberId) {
        return const HardRuleResult.rejected('wrong selected member');
      }
    }

    final int topCount = _count(candidate, GarmentCategory.top);
    final int bottomCount = _count(candidate, GarmentCategory.bottom);
    final int dressCount = _count(candidate, GarmentCategory.dress);
    final int shoeCount = _count(candidate, GarmentCategory.shoe);

    if (shoeCount != 1) {
      return const HardRuleResult.rejected('must contain exactly one shoes');
    }

    if (candidate.templateType == OotdTemplateType.separated) {
      if (topCount != 1 || bottomCount != 1 || dressCount != 0) {
        return const HardRuleResult.rejected(
          'invalid separated outfit structure',
        );
      }
    } else {
      if (dressCount != 1 || topCount != 0 || bottomCount != 0) {
        return const HardRuleResult.rejected('invalid dress outfit structure');
      }
    }

    if (requirements.rainProtectionNeed >= 8.5 &&
        candidate.garments.any(_isSuedeOrOpenFootwear)) {
      return const HardRuleResult.rejected(
        'extreme rain conflict with suede or open footwear',
      );
    }

    final double weightedWarmth = _weightedWarmth(candidate);
    if (requirements.targetWarmth >= 8.5 && weightedWarmth <= 2.5) {
      return const HardRuleResult.rejected('extreme cold incompatibility');
    }

    if (requirements.targetWarmth <= 2 && weightedWarmth >= 8.5) {
      return const HardRuleResult.rejected('extreme heat incompatibility');
    }

    return const HardRuleResult.accepted();
  }

  int _count(OutfitCandidate candidate, GarmentCategory category) {
    return candidate.garments
        .where((Garment garment) => garment.category == category)
        .length;
  }

  bool _isSuedeOrOpenFootwear(Garment garment) {
    final String fabric = garment.fabric?.toLowerCase() ?? '';
    final String name = '${garment.name} ${garment.subcategory ?? ''}'
        .toLowerCase();

    return fabric.contains('suede') ||
        (garment.category == GarmentCategory.shoe &&
            (name.contains('sandal') ||
                name.contains('slides') ||
                name.contains('open')));
  }

  double _weightedWarmth(OutfitCandidate candidate) {
    double weighted = 0;
    double totalWeight = 0;

    for (final Garment garment in candidate.garments) {
      final double weight = switch (garment.category) {
        GarmentCategory.outerwear => 1.6,
        GarmentCategory.top ||
        GarmentCategory.bottom ||
        GarmentCategory.dress => 1.0,
        GarmentCategory.shoe => 0.45,
        _ => 0.15,
      };

      weighted += metadataInterpreter.interpret(garment).warmth * weight;
      totalWeight += weight;
    }

    return totalWeight == 0 ? 5 : weighted / totalWeight;
  }
}
