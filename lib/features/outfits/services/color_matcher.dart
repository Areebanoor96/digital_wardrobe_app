import 'dart:math';

import 'package:digital_wardrobe_app/data/models/garment.dart';

class ColorMatcher {
  const ColorMatcher();

  int score(
      Garment first,
      Garment second,
      ) {
    final String? firstHex = first.colorHex;
    final String? secondHex = second.colorHex;

    if (firstHex == null || secondHex == null) {
      return 5;
    }

    final String cleanFirst = _cleanHex(firstHex);
    final String cleanSecond = _cleanHex(secondHex);

    if (cleanFirst == cleanSecond) {
      return 7;
    }

    if (_isNeutral(cleanFirst) || _isNeutral(cleanSecond)) {
      return 10;
    }

    final double distance = _colorDistance(
      cleanFirst,
      cleanSecond,
    );

    if (distance >= 180) {
      return 10;
    }

    if (distance >= 100) {
      return 8;
    }

    if (distance >= 60) {
      return 6;
    }

    return 4;
  }

  String _cleanHex(String value) {
    return value.replaceFirst('#', '').toLowerCase();
  }

  bool _isNeutral(String value) {
    const Set<String> neutrals = <String>{
      '000000',
      'ffffff',
      '808080',
      'c0c0c0',
      'd3d3d3',
      '696969',
      'f5f5f5',
      'd2b48c',
      'f5f5dc',
    };

    return neutrals.contains(value);
  }

  double _colorDistance(
      String first,
      String second,
      ) {
    try {
      final int r1 = int.parse(first.substring(0, 2), radix: 16);
      final int g1 = int.parse(first.substring(2, 4), radix: 16);
      final int b1 = int.parse(first.substring(4, 6), radix: 16);

      final int r2 = int.parse(second.substring(0, 2), radix: 16);
      final int g2 = int.parse(second.substring(2, 4), radix: 16);
      final int b2 = int.parse(second.substring(4, 6), radix: 16);

      return sqrt(
        pow(r1 - r2, 2) +
            pow(g1 - g2, 2) +
            pow(b1 - b2, 2),
      );
    } catch (_) {
      return 0;
    }
  }
}