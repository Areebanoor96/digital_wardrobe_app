import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/ootd_recommendation_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('restores the exact persisted OOTD recommendation fields', () {
    final OotdRecommendationSnapshot snapshot =
        OotdRecommendationSnapshot.fromJson(<String, dynamic>{
          'id': 'snapshot-1',
          'user_id': 'user-1',
          'member_id': 'member-1',
          'garment_ids': <String>['top-1', 'bottom-1'],
          'score': 92,
          'reason': 'Best Match: 92% match.',
          'reasons': <String>['Good weather fit', 'Strong color balance'],
          'context': <String, dynamic>{'occasion': 'casual'},
          'weather_snapshot': <String, dynamic>{'temperature': 24},
          'created_at': '2026-08-28T07:00:00Z',
          'expires_at': '2026-08-29T07:00:00Z',
        });

    final recommendation = snapshot.toRecommendation(<Garment>[
      _garment(id: 'top-1', name: 'Top'),
      _garment(id: 'bottom-1', name: 'Bottom'),
    ]);

    expect(recommendation.garments.map((Garment g) => g.id), <String>[
      'top-1',
      'bottom-1',
    ]);
    expect(recommendation.score, 92);
    expect(recommendation.reason, 'Best Match: 92% match.');
    expect(recommendation.reasons, <String>[
      'Good weather fit',
      'Strong color balance',
    ]);
    expect(snapshot.context['occasion'], 'casual');
    expect(snapshot.weatherSnapshot['temperature'], 24);
  });

  test('flags missing and unavailable snapshot garments safely', () {
    final RestoredOotdRecommendation restored = RestoredOotdRecommendation(
      snapshot: OotdRecommendationSnapshot.fromJson(<String, dynamic>{
        'id': 'snapshot-1',
        'user_id': 'user-1',
        'member_id': 'member-1',
        'garment_ids': <String>['top-1', 'missing-1'],
        'score': 80,
        'reason': 'Stored suggestion.',
        'reasons': const <String>[],
        'context': const <String, dynamic>{},
        'weather_snapshot': const <String, dynamic>{},
        'created_at': '2026-08-28T07:00:00Z',
        'expires_at': '2026-08-29T07:00:00Z',
      }),
      garments: <Garment>[
        _garment(
          id: 'top-1',
          name: 'Top',
          laundryStatus: LaundryStatus.dirty,
        ),
      ],
      missingGarmentIds: const <String>['missing-1'],
      unavailableGarmentIds: const <String>['top-1'],
    );

    expect(restored.hasMissingGarments, isTrue);
    expect(restored.hasUnavailableGarments, isTrue);
    expect(restored.canUseRecommendation, isFalse);
    expect(restored.recommendation.garments.single.id, 'top-1');
  });
}

Garment _garment({
  required String id,
  required String name,
  LaundryStatus laundryStatus = LaundryStatus.clean,
}) {
  return Garment(
    id: id,
    name: name,
    memberId: 'member-1',
    category: GarmentCategory.top,
    photoPaths: const <String>[],
    photoUrls: const <String>[],
    laundryStatus: laundryStatus,
  );
}
