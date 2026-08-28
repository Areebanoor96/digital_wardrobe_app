import 'package:digital_wardrobe_app/data/models/alert.dart';

String? routeForAlert(Alert alert) {
  final String? route = alert.actionPayload['route'] as String?;
  if (route != null && route.trim().isNotEmpty) {
    return route;
  }

  final String? targetId = alert.targetId;
  final String? targetType = alert.targetType;

  if (targetId != null && targetId.trim().isNotEmpty) {
    return switch (targetType) {
      AlertTargetTypes.garment => '/garments/$targetId',
      AlertTargetTypes.familyMember => '/family/$targetId',
      AlertTargetTypes.ootdRecommendation => '/ootd/recommendations/$targetId',
      AlertTargetTypes.outfit => '/outfits/$targetId',
      _ => null,
    };
  }

  final String? legacyGarmentId = alert.garmentId;
  if (legacyGarmentId != null && legacyGarmentId.trim().isNotEmpty) {
    return '/garments/$legacyGarmentId';
  }

  return null;
}
