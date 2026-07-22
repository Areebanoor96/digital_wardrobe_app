import 'dart:math';

import 'package:digital_wardrobe_app/data/models/garment.dart';

class OutfitRecommendation {
  const OutfitRecommendation({
    required this.garments,
    required this.reason,
  });

  final List<Garment> garments;
  final String reason;
}

class OutfitRecommendationService {
  OutfitRecommendationService();

  OutfitRecommendation recommend({
    required List<Garment> allGarments,
    required Set<String> recentlyWornGarmentIds,
  }) {
    final List<Garment> candidates = allGarments
        .where(
          (Garment g) =>
              !g.isArchived &&
              g.laundryStatus == LaundryStatus.clean &&
              g.photoUrls.isNotEmpty,
        )
        .toList();

    candidates.sort((Garment a, Garment b) {
      final bool aRecent = recentlyWornGarmentIds.contains(a.id);
      final bool bRecent = recentlyWornGarmentIds.contains(b.id);
      if (aRecent && !bRecent) return 1;
      if (!aRecent && bRecent) return -1;
      if (a.lastWornDate == null && b.lastWornDate != null) return -1;
      if (a.lastWornDate != null && b.lastWornDate == null) return 1;
      if (a.lastWornDate != null && b.lastWornDate != null) {
        return a.lastWornDate!.compareTo(b.lastWornDate!);
      }
      return 0;
    });

    final List<Garment> tops = candidates
        .where((Garment g) => g.category == GarmentCategory.top)
        .toList();
    final List<Garment> bottoms = candidates
        .where((Garment g) => g.category == GarmentCategory.bottom)
        .toList();
    final List<Garment> dresses = candidates
        .where((Garment g) => g.category == GarmentCategory.dress)
        .toList();
    final List<Garment> outerwears = candidates
        .where((Garment g) => g.category == GarmentCategory.outerwear)
        .toList();
    final List<Garment> shoes = candidates
        .where((Garment g) => g.category == GarmentCategory.shoe)
        .toList();
    final List<Garment> accessories = candidates
        .where(
          (Garment g) =>
              g.category == GarmentCategory.accessory ||
              g.category == GarmentCategory.jewelry ||
              g.category == GarmentCategory.bag,
        )
        .toList();

    if (dresses.isNotEmpty) {
      final Garment dress = dresses.first;
      final List<Garment> extras = _pickExtras(
        mainGarment: dress,
        outerwears: outerwears,
        shoes: shoes,
        accessories: accessories,
      );
      return OutfitRecommendation(
        garments: [dress, ...extras],
        reason: 'Your ${dress.name} is a great choice — it\'s ready to wear.',
      );
    }

    if (tops.isNotEmpty && bottoms.isNotEmpty) {
      final Garment top = tops.first;
      final Garment bottom = _pickBottom(top, bottoms);
      final List<Garment> extras = _pickExtras(
        mainGarment: top,
        outerwears: outerwears,
        shoes: shoes,
        accessories: accessories,
      );
      return OutfitRecommendation(
        garments: [top, bottom, ...extras],
        reason: _buildReason(top, bottom, recentlyWornGarmentIds),
      );
    }

    if (tops.length >= 2) {
      return OutfitRecommendation(
        garments: [tops.first, tops[1]],
        reason: 'Pair two tops for a layered look.',
      );
    }

    if (candidates.isNotEmpty) {
      return OutfitRecommendation(
        garments: [candidates.first],
        reason: 'Start building from this piece.',
      );
    }

    return OutfitRecommendation(
      garments: <Garment>[],
      reason: 'Add some clean garments to your wardrobe to get a recommendation.',
    );
  }

  Garment _pickBottom(Garment top, List<Garment> bottoms) {
    if (top.colorHex == null || bottoms.length == 1) return bottoms.first;
    for (final Garment b in bottoms) {
      if (b.colorHex != null && !_areSameColor(top.colorHex!, b.colorHex!)) {
        return b;
      }
    }
    return bottoms.first;
  }

  List<Garment> _pickExtras({
    required Garment mainGarment,
    required List<Garment> outerwears,
    required List<Garment> shoes,
    required List<Garment> accessories,
  }) {
    final List<Garment> extras = <Garment>[];
    final Set<String> usedIds = <String>{mainGarment.id};

    void addIfNotUsed(List<Garment> source) {
      for (final Garment g in source) {
        if (!usedIds.contains(g.id)) {
          extras.add(g);
          usedIds.add(g.id);
          return;
        }
      }
    }

    if (shoes.isNotEmpty) addIfNotUsed(shoes);
    if (outerwears.isNotEmpty && Random().nextBool()) addIfNotUsed(outerwears);
    if (accessories.isNotEmpty && Random().nextBool()) addIfNotUsed(accessories);

    return extras;
  }

  bool _areSameColor(String hexA, String hexB) {
    final String cleanA = hexA.replaceFirst('#', '').toLowerCase();
    final String cleanB = hexB.replaceFirst('#', '').toLowerCase();
    if (cleanA == cleanB) return true;
    final Set<String> neutrals = <String>{
      '000000', 'ffffff', '808080', 'c0c0c0',
      'd3d3d3', '696969', 'f5f5f5', 'd2b48c',
    };
    if (neutrals.contains(cleanA) || neutrals.contains(cleanB)) return false;
    try {
      final int r1 = int.parse(cleanA.substring(0, 2), radix: 16);
      final int g1 = int.parse(cleanA.substring(2, 4), radix: 16);
      final int b1 = int.parse(cleanA.substring(4, 6), radix: 16);
      final int r2 = int.parse(cleanB.substring(0, 2), radix: 16);
      final int g2 = int.parse(cleanB.substring(2, 4), radix: 16);
      final int b2 = int.parse(cleanB.substring(4, 6), radix: 16);
      final double distance = _colorDistance(r1, g1, b1, r2, g2, b2);
      return distance < 60;
    } catch (_) {
      return false;
    }
  }

  double _colorDistance(int r1, int g1, int b1, int r2, int g2, int b2) {
    return sqrt(
      (r1 - r2) * (r1 - r2) +
      (g1 - g2) * (g1 - g2) +
      (b1 - b2) * (b1 - b2),
    );
  }

  String _buildReason(
    Garment top,
    Garment bottom,
    Set<String> recentlyWornGarmentIds,
  ) {
    final bool topRecent = recentlyWornGarmentIds.contains(top.id);
    final bool bottomRecent = recentlyWornGarmentIds.contains(bottom.id);
    if (top.lastWornDate == null && bottom.lastWornDate == null) {
      return 'Fresh picks — neither ${top.name} nor ${bottom.name} has been worn yet.';
    }
    if (!topRecent && !bottomRecent && top.lastWornDate != null && bottom.lastWornDate != null) {
      return 'Both ${top.name} and ${bottom.name} haven\'t been worn recently — time to rotate them in!';
    }
    return '${top.name} pairs well with ${bottom.name}.';
  }
}
