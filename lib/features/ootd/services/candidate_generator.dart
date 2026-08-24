import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/ootd/models/outfit_candidate.dart';
import 'package:digital_wardrobe_app/features/ootd/rules/outfit_templates.dart';

class CandidateGenerator {
  const CandidateGenerator({
    this.maxPerRequiredCategory = 10,
    this.maxOptionalPerCategory = 5,
    this.maxCandidates = 700,
  });

  final int maxPerRequiredCategory;
  final int maxOptionalPerCategory;
  final int maxCandidates;

  List<OutfitCandidate> generate(List<Garment> garments) {
    final Map<GarmentCategory, List<Garment>> byCategory =
        <GarmentCategory, List<Garment>>{};

    for (final Garment garment in garments) {
      byCategory.putIfAbsent(garment.category, () => <Garment>[]).add(garment);
    }

    for (final List<Garment> bucket in byCategory.values) {
      bucket.sort(_stableGarmentSort);
    }

    final List<OutfitCandidate> candidates = <OutfitCandidate>[];

    if (OutfitTemplates.separated.canBuildFrom(garments)) {
      final List<Garment> tops = _takeRequired(byCategory[GarmentCategory.top]);
      final List<Garment> bottoms = _takeRequired(
        byCategory[GarmentCategory.bottom],
      );
      final List<Garment> shoes = _takeRequired(
        byCategory[GarmentCategory.shoe],
      );

      for (final Garment top in tops) {
        for (final Garment bottom in bottoms) {
          for (final Garment shoe in shoes) {
            _addOptionalVariants(
              candidates,
              type: OotdTemplateType.separated,
              base: <Garment>[top, bottom, shoe],
              byCategory: byCategory,
            );
            if (candidates.length >= maxCandidates) {
              return candidates;
            }
          }
        }
      }
    }

    if (OutfitTemplates.dress.canBuildFrom(garments)) {
      final List<Garment> dresses = _takeRequired(
        byCategory[GarmentCategory.dress],
      );
      final List<Garment> shoes = _takeRequired(
        byCategory[GarmentCategory.shoe],
      );

      for (final Garment dress in dresses) {
        for (final Garment shoe in shoes) {
          _addOptionalVariants(
            candidates,
            type: OotdTemplateType.dress,
            base: <Garment>[dress, shoe],
            byCategory: byCategory,
          );
          if (candidates.length >= maxCandidates) {
            return candidates;
          }
        }
      }
    }

    return candidates;
  }

  void _addOptionalVariants(
    List<OutfitCandidate> candidates, {
    required OotdTemplateType type,
    required List<Garment> base,
    required Map<GarmentCategory, List<Garment>> byCategory,
  }) {
    final List<Garment?> outerwearOptions = <Garment?>[
      null,
      ..._takeOptional(byCategory[GarmentCategory.outerwear]),
    ];
    final List<Garment?> accentOptions = <Garment?>[
      null,
      ..._takeOptional(byCategory[GarmentCategory.accessory]),
      ..._takeOptional(byCategory[GarmentCategory.jewelry]),
      ..._takeOptional(byCategory[GarmentCategory.bag]),
    ].take(maxOptionalPerCategory + 1).toList();

    for (final Garment? outerwear in outerwearOptions) {
      for (final Garment? accent in accentOptions) {
        candidates.add(
          OutfitCandidate(
            templateType: type,
            garments: <Garment>[...base, ?outerwear, ?accent],
          ),
        );
      }
    }
  }

  List<Garment> _takeRequired(List<Garment>? garments) {
    return (garments ?? const <Garment>[])
        .take(maxPerRequiredCategory)
        .toList();
  }

  List<Garment> _takeOptional(List<Garment>? garments) {
    return (garments ?? const <Garment>[])
        .take(maxOptionalPerCategory)
        .toList();
  }

  int _stableGarmentSort(Garment a, Garment b) {
    final int wearCompare = a.wearCount.compareTo(b.wearCount);
    if (wearCompare != 0) {
      return wearCompare;
    }

    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }
}
