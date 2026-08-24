import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/ootd/models/ootd_score.dart';
import 'package:digital_wardrobe_app/features/ootd/models/outfit_candidate.dart';
import 'package:digital_wardrobe_app/features/ootd/services/garment_metadata_interpreter.dart';

class StyleCompatibilityScorer {
  const StyleCompatibilityScorer({
    this.metadataInterpreter = const GarmentMetadataInterpreter(),
  });

  final GarmentMetadataInterpreter metadataInterpreter;

  OotdComponentScore score(OutfitCandidate candidate) {
    double score = 78;

    final int strongPatterns = candidate.garments
        .where(
          (Garment g) => metadataInterpreter.interpret(g).visualIntensity >= 7,
        )
        .length;
    final int subtlePatterns = candidate.garments.where((Garment g) {
      final double intensity = metadataInterpreter.interpret(g).visualIntensity;
      return intensity >= 4 && intensity < 7;
    }).length;

    if (strongPatterns >= 2) {
      score -= 18;
    } else if (strongPatterns == 1 && subtlePatterns <= 1) {
      score += 5;
    }

    score += _fitBalance(candidate);
    score += _fabricCompatibility(candidate);

    final List<String> reasons = <String>[];
    if (strongPatterns <= 1) {
      reasons.add('Pattern balance avoids too many dominant pieces.');
    }
    if (_fitBalance(candidate) > 0) {
      reasons.add('The silhouettes create a balanced shape.');
    }
    if (_fabricCompatibility(candidate) > 0) {
      reasons.add('The fabrics work naturally together.');
    }

    return OotdComponentScore(
      score: score.clamp(0, 100).toDouble(),
      reasons: reasons,
    );
  }

  double _fitBalance(OutfitCandidate candidate) {
    final Garment? top = _first(candidate, GarmentCategory.top);
    final Garment? bottom = _first(candidate, GarmentCategory.bottom);
    final Garment? outerwear = _first(candidate, GarmentCategory.outerwear);

    final String topFit = _normalize(top?.fit);
    final String bottomFit = _normalize(bottom?.fit);
    final String outerFit = _normalize(outerwear?.fit);

    if ((topFit == 'slim' || topFit == 'tailored') &&
        (bottomFit == 'wide-leg' || bottomFit == 'straight')) {
      return 7;
    }
    if ((topFit == 'oversized' || topFit == 'relaxed') &&
        (bottomFit == 'slim' ||
            bottomFit == 'straight' ||
            bottomFit == 'tapered')) {
      return 7;
    }
    if (topFit == 'oversized' &&
        bottomFit == 'wide-leg' &&
        outerFit == 'oversized') {
      return -10;
    }
    if (outerFit == 'structured' || outerFit == 'tailored') {
      return 4;
    }

    return 0;
  }

  double _fabricCompatibility(OutfitCandidate candidate) {
    final Set<String> fabrics = candidate.garments
        .map((Garment garment) => _normalize(garment.fabric))
        .where((String fabric) => fabric.isNotEmpty)
        .toSet();

    double score = 0;
    if (fabrics.contains('cotton') && fabrics.contains('denim')) {
      score += 5;
    }
    if (fabrics.contains('linen') && fabrics.contains('cotton')) {
      score += 5;
    }
    if (fabrics.contains('silk') &&
        (fabrics.contains('tweed') || fabrics.contains('wool'))) {
      score += 4;
    }
    if (fabrics.contains('wool') &&
        (fabrics.contains('knit') || fabrics.contains('cashmere'))) {
      score += 4;
    }
    if (fabrics.contains('leather') && fabrics.contains('denim')) {
      score += 4;
    }

    return score.clamp(0, 10).toDouble();
  }

  Garment? _first(OutfitCandidate candidate, GarmentCategory category) {
    return candidate.garments
        .where((Garment garment) => garment.category == category)
        .firstOrNull;
  }

  String _normalize(String? value) => value?.trim().toLowerCase() ?? '';
}
