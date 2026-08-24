import 'dart:math';

import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/ootd/models/ootd_score.dart';
import 'package:digital_wardrobe_app/features/ootd/models/outfit_candidate.dart';

class ColorHarmonyScorer {
  const ColorHarmonyScorer();

  OotdComponentScore score(OutfitCandidate candidate) {
    final List<_ColorInfo> colors = candidate.garments
        .expand(
          (Garment garment) => <String?>[
            garment.colorHex,
            garment.secondaryColorHex,
          ],
        )
        .map(_ColorInfo.fromHex)
        .whereType<_ColorInfo>()
        .toList();

    if (colors.length < 2) {
      return const OotdComponentScore(score: 72);
    }

    final int neutralCount = colors.where((_ColorInfo c) => c.isNeutral).length;
    final List<_ColorInfo> chromatic = colors
        .where((_ColorInfo c) => !c.isNeutral)
        .toList();

    double score = 72;

    if (neutralCount == colors.length) {
      score = 86;
    } else if (neutralCount >= colors.length - 1) {
      score = 90;
    } else {
      final List<double> hues = chromatic.map((_ColorInfo c) => c.hue).toList();
      final double maxHarmony = _bestHueHarmony(hues);
      score = max(score, maxHarmony);
    }

    final int saturatedCount = colors
        .where((_ColorInfo c) => c.saturation >= 0.62 && !c.isNeutral)
        .length;
    if (saturatedCount >= 3) {
      score -= 18;
    } else if (saturatedCount == 2 && neutralCount == 0) {
      score -= 8;
    }

    final double lightnessSpread =
        colors.map((_ColorInfo c) => c.lightness).reduce(max) -
        colors.map((_ColorInfo c) => c.lightness).reduce(min);
    if (lightnessSpread >= 0.45) {
      score += 4;
    }

    final List<String> reasons = <String>[];
    if (score >= 84) {
      reasons.add('The color palette is balanced across the full outfit.');
    }
    if (neutralCount >= colors.length - 1) {
      reasons.add('Neutral pieces keep the palette easy to wear.');
    }

    return OotdComponentScore(
      score: score.clamp(0, 100).toDouble(),
      reasons: reasons,
    );
  }

  double _bestHueHarmony(List<double> hues) {
    if (hues.length < 2) {
      return 76;
    }

    final List<double> distances = <double>[];
    for (int i = 0; i < hues.length; i++) {
      for (int j = i + 1; j < hues.length; j++) {
        distances.add(_hueDistance(hues[i], hues[j]));
      }
    }

    final double average =
        distances.reduce((double a, double b) => a + b) / distances.length;

    if (average <= 18) {
      return 88; // monochromatic / tonal
    }
    if (average <= 45) {
      return 84; // analogous
    }
    if (distances.any((double d) => d >= 150 && d <= 210)) {
      return 82; // complementary accent
    }
    if (average <= 95) {
      return 76;
    }

    return 66;
  }

  double _hueDistance(double a, double b) {
    final double diff = (a - b).abs();
    return diff > 180 ? 360 - diff : diff;
  }
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

  bool get isNeutral => saturation <= 0.14 || lightness <= 0.08;

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
