import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/ootd_recommendation_snapshot.dart';
import 'package:digital_wardrobe_app/data/repositories/alerts_repository.dart';
import 'package:digital_wardrobe_app/data/repositories/garment_repository.dart';
import 'package:digital_wardrobe_app/data/repositories/ootd_recommendation_repository.dart';
import 'package:digital_wardrobe_app/features/ootd/models/weather_data.dart';
import 'package:digital_wardrobe_app/features/ootd/services/outfit_recommendation_service.dart';
import 'package:digital_wardrobe_app/features/outfits/models/outfit_context.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AlertsRepository OOTD creation gating', () {
    test('eligible wardrobe with no active alert can generate an OOTD alert', () {
      expect(
        AlertsRepository.shouldCreateOotdAlert(
          enabled: true,
          hasActiveOotdAlert: false,
          isOotdEligible: true,
        ),
        isTrue,
      );
    });

    test('normal provider rebuilds never duplicate an active OOTD alert', () {
      expect(
        AlertsRepository.shouldCreateOotdAlert(
          enabled: true,
          hasActiveOotdAlert: true,
          isOotdEligible: true,
        ),
        isFalse,
      );
    });

    test('dismissed OOTD alert no longer blocks a fresh alert later that day', () {
      // A dismissed alert is not "active", so hasActiveOotdAlert is false and a
      // later valid generation attempt is allowed to create a new alert.
      expect(
        AlertsRepository.shouldCreateOotdAlert(
          enabled: true,
          hasActiveOotdAlert: false,
          isOotdEligible: true,
        ),
        isTrue,
      );
    });

    test('disabled preference blocks OOTD alert creation', () {
      expect(
        AlertsRepository.shouldCreateOotdAlert(
          enabled: false,
          hasActiveOotdAlert: false,
          isOotdEligible: true,
        ),
        isFalse,
      );
    });

    test('ineligible wardrobe blocks OOTD alert creation', () {
      expect(
        AlertsRepository.shouldCreateOotdAlert(
          enabled: true,
          hasActiveOotdAlert: false,
          isOotdEligible: false,
        ),
        isFalse,
      );
    });
  });

  group('AlertsRepository OOTD resolution', () {
    test('an enabled preference never auto-dismisses an OOTD alert', () {
      expect(AlertsRepository.shouldResolveOotdAlert(enabled: true), isFalse);
    });

    test('wearing garments (later ineligible wardrobe) never auto-dismisses', () {
      // Regression: generating a fresh OOTD alert when the wardrobe is
      // temporarily ineligible (e.g. garments freshly worn and marked dirty)
      // must not destroy the day's already-generated OOTD alert.
      expect(AlertsRepository.shouldResolveOotdAlert(enabled: true), isFalse);
    });

    test('a disabled preference resolves existing OOTD alerts', () {
      expect(AlertsRepository.shouldResolveOotdAlert(enabled: false), isTrue);
    });
  });

  group('AlertsRepository OOTD snapshot failure isolation', () {
    test('snapshot persistence failure returns null instead of breaking the feed', () async {
      final AlertsRepository repository = AlertsRepository(
        SupabaseClient('https://example.supabase.co', 'anon-key'),
        ootdRecommendationRepository: _ThrowingOotdRepository(),
      );

      final Map<String, dynamic>? alert = await repository
          .buildOotdAlertWithSnapshot(
            userId: 'user-1',
            memberId: 'member-1',
            recommendation: _recommendation(),
            enabled: true,
            hasActiveOotdAlert: false,
            isOotdEligible: true,
          );

      expect(alert, isNull);
    });
  });
}

OutfitRecommendation _recommendation() {
  return OutfitRecommendation(
    garments: <Garment>[
      Garment(
        id: 'garment-top',
        name: 'Shirt',
        category: GarmentCategory.top,
        photoPaths: const <String>[],
        photoUrls: const <String>[],
      ),
      Garment(
        id: 'garment-bottom',
        name: 'Jeans',
        category: GarmentCategory.bottom,
        photoPaths: const <String>[],
        photoUrls: const <String>[],
      ),
      Garment(
        id: 'garment-shoe',
        name: 'Sneakers',
        category: GarmentCategory.shoe,
        photoPaths: const <String>[],
        photoUrls: const <String>[],
      ),
    ],
    reason: 'Best Match: 88% match. Balanced across all scorers.',
    score: 88,
  );
}

class _ThrowingOotdRepository extends OotdRecommendationRepository {
  _ThrowingOotdRepository()
    : super(
        SupabaseClient('https://example.supabase.co', 'anon-key'),
        GarmentRepository(SupabaseClient('https://example.supabase.co', 'anon-key')),
      );

  @override
  Future<OotdRecommendationSnapshot> createSnapshot({
    required String memberId,
    required OutfitRecommendation recommendation,
    OutfitContext context = const OutfitContext(),
    WeatherData? weather,
    DateTime? expiresAt,
  }) async {
    throw StateError('snapshot insert failed');
  }
}