import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/ootd/services/outfit_recommendation_service.dart';

class OotdRecommendationSnapshot {
  const OotdRecommendationSnapshot({
    required this.id,
    required this.userId,
    required this.memberId,
    required this.garmentIds,
    required this.score,
    required this.reason,
    required this.reasons,
    required this.context,
    required this.weatherSnapshot,
    required this.createdAt,
    required this.expiresAt,
  });

  final String id;
  final String userId;
  final String memberId;
  final List<String> garmentIds;
  final int score;
  final String reason;
  final List<String> reasons;
  final Map<String, dynamic> context;
  final Map<String, dynamic> weatherSnapshot;
  final DateTime createdAt;
  final DateTime expiresAt;

  factory OotdRecommendationSnapshot.fromJson(Map<String, dynamic> json) {
    return OotdRecommendationSnapshot(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      memberId: json['member_id'] as String,
      garmentIds: List<String>.from(
        json['garment_ids'] as List<dynamic>? ?? const <dynamic>[],
      ),
      score: json['score'] as int? ?? 0,
      reason: json['reason'] as String? ?? '',
      reasons: _stringListFromJson(json['reasons']),
      context: _mapFromJson(json['context']),
      weatherSnapshot: _mapFromJson(json['weather_snapshot']),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      expiresAt:
          DateTime.tryParse(json['expires_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  OutfitRecommendation toRecommendation(List<Garment> garments) {
    return OutfitRecommendation(
      garments: garments,
      reason: reason,
      score: score,
      heroGarment: garments.firstOrNull,
      reasons: reasons,
    );
  }

  static List<String> _stringListFromJson(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }

    return value
        .whereType<String>()
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList();
  }

  static Map<String, dynamic> _mapFromJson(dynamic value) {
    if (value is! Map) {
      return const <String, dynamic>{};
    }

    return Map<String, dynamic>.from(value);
  }
}

class RestoredOotdRecommendation {
  const RestoredOotdRecommendation({
    required this.snapshot,
    required this.garments,
    required this.missingGarmentIds,
    required this.unavailableGarmentIds,
  });

  final OotdRecommendationSnapshot snapshot;
  final List<Garment> garments;
  final List<String> missingGarmentIds;
  final List<String> unavailableGarmentIds;

  OutfitRecommendation get recommendation => snapshot.toRecommendation(garments);

  bool get hasMissingGarments => missingGarmentIds.isNotEmpty;

  bool get hasUnavailableGarments => unavailableGarmentIds.isNotEmpty;

  bool get canUseRecommendation =>
      garments.isNotEmpty && !hasMissingGarments && !hasUnavailableGarments;
}
