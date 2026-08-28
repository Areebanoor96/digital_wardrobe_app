import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/ootd_recommendation_snapshot.dart';
import 'package:digital_wardrobe_app/data/repositories/garment_repository.dart';
import 'package:digital_wardrobe_app/features/ootd/models/weather_data.dart';
import 'package:digital_wardrobe_app/features/ootd/services/outfit_recommendation_service.dart';
import 'package:digital_wardrobe_app/features/outfits/models/outfit_context.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OotdRecommendationRepository {
  OotdRecommendationRepository(this._client, this._garmentRepository);

  final SupabaseClient _client;
  final GarmentRepository _garmentRepository;

  static Map<String, dynamic> buildSnapshotInsertRow({
    required String userId,
    required String memberId,
    required OutfitRecommendation recommendation,
    OutfitContext context = const OutfitContext(),
    WeatherData? weather,
    required DateTime expiresAt,
  }) {
    return <String, dynamic>{
      'user_id': userId,
      'member_id': memberId,
      'garment_ids': recommendation.garments
          .map((Garment garment) => garment.id)
          .toList(),
      'score': recommendation.score,
      'reason': recommendation.reason,
      'reasons': recommendation.reasons,
      'context': _contextToJson(context),
      'weather_snapshot': _weatherToJson(weather),
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  Future<OotdRecommendationSnapshot> createSnapshot({
    required String memberId,
    required OutfitRecommendation recommendation,
    OutfitContext context = const OutfitContext(),
    WeatherData? weather,
    DateTime? expiresAt,
  }) async {
    final String userId = _client.auth.currentUser!.id;
    final DateTime resolvedExpiresAt =
        expiresAt ?? DateTime.now().toUtc().add(const Duration(days: 1));

    final Map<String, dynamic> row = Map<String, dynamic>.from(
      await _client
              .from('ootd_recommendations')
              .insert(
                buildSnapshotInsertRow(
                  userId: userId,
                  memberId: memberId,
                  recommendation: recommendation,
                  context: context,
                  weather: weather,
                  expiresAt: resolvedExpiresAt,
                ),
              )
              .select()
              .single()
          as Map,
    );

    return OotdRecommendationSnapshot.fromJson(row);
  }

  Future<RestoredOotdRecommendation> fetchRestoredRecommendation({
    required String snapshotId,
    required String memberId,
  }) async {
    final String userId = _client.auth.currentUser!.id;
    final Map<String, dynamic> row = Map<String, dynamic>.from(
      await _client
              .from('ootd_recommendations')
              .select()
              .eq('id', snapshotId)
              .eq('user_id', userId)
              .eq('member_id', memberId)
              .single()
          as Map,
    );

    final OotdRecommendationSnapshot snapshot =
        OotdRecommendationSnapshot.fromJson(row);
    final List<Garment> garments = await _garmentRepository.fetchGarmentsByIds(
      memberId: memberId,
      garmentIds: snapshot.garmentIds,
    );
    final Set<String> loadedIds = garments
        .map((Garment garment) => garment.id)
        .toSet();

    final List<String> missingIds = snapshot.garmentIds
        .where((String id) => !loadedIds.contains(id))
        .toList();
    final List<String> unavailableIds = garments
        .where((Garment garment) => !_isCurrentlyUsable(garment))
        .map((Garment garment) => garment.id)
        .toList();

    return RestoredOotdRecommendation(
      snapshot: snapshot,
      garments: garments,
      missingGarmentIds: missingIds,
      unavailableGarmentIds: unavailableIds,
    );
  }

  static Map<String, dynamic> _contextToJson(OutfitContext context) {
    return <String, dynamic>{
      'hero_garment_id': context.heroGarment?.id,
      'occasion': context.occasion,
      'season': context.season,
      'mood': context.mood,
      'dress_code': context.dressCode,
      'expected_activity_level': context.expectedActivityLevel,
      'indoor': context.indoor,
      'outdoor': context.outdoor,
      'require_clean_garments': context.requireCleanGarments,
    };
  }

  static Map<String, dynamic> _weatherToJson(WeatherData? weather) {
    if (weather == null) {
      return const <String, dynamic>{};
    }

    return <String, dynamic>{
      'temperature': weather.temperature,
      'feels_like': weather.feelsLike,
      'min_temperature': weather.minTemperature,
      'max_temperature': weather.maxTemperature,
      'humidity': weather.humidity,
      'rain_probability': weather.rainProbability,
      'wind_speed': weather.windSpeed,
      'uv_index': weather.uvIndex,
      'condition': weather.condition,
      'has_rain_or_snow': weather.hasRainOrSnow,
      'fetched_at': weather.fetchedAt?.toIso8601String(),
      'latitude': weather.latitude,
      'longitude': weather.longitude,
    };
  }

  bool _isCurrentlyUsable(Garment garment) {
    return !garment.isArchived &&
        garment.laundryStatus == LaundryStatus.clean &&
        garment.availabilityStatus.isPhysicallyAvailable &&
        garment.ironingStatus != IroningStatus.needsIroning;
  }
}
