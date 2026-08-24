import 'dart:math';

import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/ootd/models/garment_intelligence_metadata.dart';

class GarmentMetadataInterpreter {
  const GarmentMetadataInterpreter();

  GarmentIntelligenceMetadata interpret(Garment garment) {
    final double breathability = _breathability(garment);
    final double warmth = _warmth(garment);
    final double formality = _formality(garment);
    final double visualIntensity = _visualIntensity(garment);
    final double statementLevel = _statementLevel(
      garment,
      visualIntensity: visualIntensity,
      formality: formality,
    );

    return GarmentIntelligenceMetadata(
      formality: formality,
      warmth: warmth,
      breathability: breathability,
      visualIntensity: visualIntensity,
      versatility: _versatility(
        garment,
        visualIntensity: visualIntensity,
        statementLevel: statementLevel,
      ),
      statementLevel: statementLevel,
    );
  }

  /// Fabric breathability starts from normalized textile lookup values.
  /// Modifiers then account for weight, sleeve coverage and category.
  double _breathability(Garment garment) {
    final String fabric = _normalize(garment.fabric);
    double score = switch (fabric) {
      'linen' => 9.5,
      'cotton' || 'lawn' || 'bamboo' => 8.5,
      'rayon/viscose' || 'rayon' || 'viscose' || 'modal' => 7.2,
      'chiffon' || 'georgette' || 'chambray' => 7.0,
      'denim' || 'jersey' || 'canvas' => 5.2,
      'polyester' || 'nylon' || 'lycra/spandex' => 3.8,
      'wool' || 'flannel' || 'fleece' || 'velvet' || 'cashmere' => 3.5,
      'leather' || 'suede' => 1.8,
      _ => 5.5,
    };

    score += switch (_normalize(garment.fabricWeight)) {
      'light' => 1.0,
      'heavy' => -1.0,
      _ => 0,
    };

    score += switch (_normalize(garment.sleeveLength)) {
      'sleeveless' => 0.8,
      'short sleeve' => 0.5,
      'long sleeve' => -0.5,
      _ => 0,
    };

    if (garment.category == GarmentCategory.outerwear) {
      score -= 0.8;
    }

    return score.clamp(1, 10).toDouble();
  }

  double _warmth(Garment garment) {
    final String fabric = _normalize(garment.fabric);
    double score = switch (fabric) {
      'linen' || 'lawn' || 'chiffon' || 'georgette' => 2.0,
      'cotton' || 'bamboo' || 'rayon/viscose' || 'modal' => 3.5,
      'denim' || 'jersey' || 'corduroy' || 'khaddar' => 5.4,
      'wool' || 'flannel' || 'fleece' || 'velvet' || 'cashmere' => 8.0,
      'leather' || 'suede' || 'tweed' => 7.0,
      _ => 4.5,
    };

    score += switch (_normalize(garment.fabricWeight)) {
      'light' => -1.4,
      'medium' => 0,
      'heavy' => 1.6,
      _ => 0,
    };

    score += switch (_normalize(garment.sleeveLength)) {
      'sleeveless' => -1.2,
      'short sleeve' => -0.8,
      'three-quarter sleeve' => -0.2,
      'long sleeve' => 0.9,
      _ => 0,
    };

    score += switch (garment.category) {
      GarmentCategory.outerwear => 1.4,
      GarmentCategory.shoe => 0.3,
      GarmentCategory.accessory ||
      GarmentCategory.jewelry ||
      GarmentCategory.bag => -1.5,
      _ => 0,
    };

    return score.clamp(1, 10).toDouble();
  }

  double _formality(Garment garment) {
    double score = switch (garment.category) {
      GarmentCategory.jewelry => 6,
      GarmentCategory.bag => 5,
      GarmentCategory.outerwear => 5.5,
      GarmentCategory.dress => 5.5,
      GarmentCategory.shoe => 4.5,
      _ => 4,
    };

    final String subcategory = _normalize(garment.subcategory);
    if (subcategory.contains('blazer') ||
        subcategory.contains('suit') ||
        subcategory.contains('heel') ||
        subcategory.contains('trouser')) {
      score += 1.5;
    }
    if (subcategory.contains('tee') ||
        subcategory.contains('sneaker') ||
        subcategory.contains('hoodie') ||
        subcategory.contains('pajama')) {
      score -= 1.4;
    }

    if (_containsAny(garment.occasions, <String>['formal', 'wedding'])) {
      score += 2.2;
    } else if (_containsAny(garment.occasions, <String>['work', 'ethnic'])) {
      score += 1.3;
    } else if (_containsAny(garment.occasions, <String>['sleep', 'sport'])) {
      score -= 2.2;
    }

    score += switch (_normalize(garment.fit)) {
      'tailored' || 'structured' => 1.1,
      'slim' || 'straight' => 0.4,
      'oversized' || 'relaxed' || 'flowy' => -0.5,
      _ => 0,
    };

    score += switch (_normalize(garment.fabric)) {
      'silk' || 'satin' || 'organza' || 'tweed' => 1.0,
      'fleece' || 'jersey' || 'canvas' => -0.6,
      _ => 0,
    };

    if (_containsAny(garment.moods, <String>['elegant', 'professional'])) {
      score += 0.8;
    }
    if (_containsAny(garment.moods, <String>['sporty', 'relaxed'])) {
      score -= 0.4;
    }

    return score.clamp(1, 10).toDouble();
  }

  double _visualIntensity(Garment garment) {
    double score = switch (_normalize(garment.pattern)) {
      '' || 'solid' => 2.2,
      'striped' || 'checked' || 'textured' => 4.0,
      'floral' || 'polka dot' || 'embroidered' || 'abstract' => 5.8,
      'graphic' || 'animal print' => 7.5,
      'sequined' => 9.2,
      _ => 4.5,
    };

    final _ColorInfo? primary = _ColorInfo.fromHex(garment.colorHex);
    final _ColorInfo? secondary = _ColorInfo.fromHex(garment.secondaryColorHex);

    if (primary != null) {
      score += primary.saturation >= 0.65 ? 1.2 : 0;
      score += primary.isNeutral ? -0.8 : 0;
    }

    if (secondary != null) {
      score += 0.6;
      score += secondary.saturation >= 0.65 ? 0.6 : 0;
    }

    if (_containsAny(garment.moods, <String>['bold', 'party'])) {
      score += 0.8;
    }

    return score.clamp(1, 10).toDouble();
  }

  double _statementLevel(
    Garment garment, {
    required double visualIntensity,
    required double formality,
  }) {
    double score = (visualIntensity * 0.75) + (formality >= 8 ? 0.8 : 0);
    if (garment.category == GarmentCategory.outerwear ||
        garment.category == GarmentCategory.dress) {
      score += 0.7;
    }

    return score.clamp(1, 10).toDouble();
  }

  double _versatility(
    Garment garment, {
    required double visualIntensity,
    required double statementLevel,
  }) {
    double score = 8.0;
    score -= max(0, visualIntensity - 4) * 0.45;
    score -= max(0, statementLevel - 5) * 0.35;

    if (garment.occasions.length >= 3) {
      score += 0.7;
    }
    if (_normalize(garment.pattern) == 'solid') {
      score += 0.5;
    }

    final _ColorInfo? color = _ColorInfo.fromHex(garment.colorHex);
    if (color?.isNeutral == true) {
      score += 0.8;
    }

    return score.clamp(1, 10).toDouble();
  }

  bool _containsAny(List<String> values, List<String> targets) {
    final Set<String> normalizedTargets = targets.map(_normalize).toSet();

    return values.any((String value) {
      final String normalized = _normalize(value);
      return normalizedTargets.any(normalized.contains);
    });
  }

  String _normalize(String? value) => value?.trim().toLowerCase() ?? '';
}

class _ColorInfo {
  const _ColorInfo({
    required this.hue,
    required this.saturation,
    required this.lightness,
  });

  final double hue;
  final double saturation;
  final double lightness;

  bool get isNeutral => saturation <= 0.12 || lightness <= 0.08;

  static _ColorInfo? fromHex(String? value) {
    final String cleaned = (value ?? '').replaceFirst('#', '').trim();
    if (cleaned.length != 6) {
      return null;
    }

    final int? raw = int.tryParse(cleaned, radix: 16);
    if (raw == null) {
      return null;
    }

    final double r = ((raw >> 16) & 0xff) / 255;
    final double g = ((raw >> 8) & 0xff) / 255;
    final double b = (raw & 0xff) / 255;
    final double maxValue = max(r, max(g, b));
    final double minValue = min(r, min(g, b));
    final double delta = maxValue - minValue;
    final double lightness = (maxValue + minValue) / 2;
    final double saturation = delta == 0
        ? 0
        : delta / (1 - (2 * lightness - 1).abs());

    double hue = 0;
    if (delta != 0) {
      if (maxValue == r) {
        hue = 60 * (((g - b) / delta) % 6);
      } else if (maxValue == g) {
        hue = 60 * (((b - r) / delta) + 2);
      } else {
        hue = 60 * (((r - g) / delta) + 4);
      }
    }

    return _ColorInfo(
      hue: hue < 0 ? hue + 360 : hue,
      saturation: saturation,
      lightness: lightness,
    );
  }
}
