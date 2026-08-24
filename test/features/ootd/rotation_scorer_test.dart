import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/wear_log.dart';
import 'package:digital_wardrobe_app/features/ootd/models/ootd_score.dart';
import 'package:digital_wardrobe_app/features/ootd/models/outfit_candidate.dart';
import 'package:digital_wardrobe_app/features/ootd/scoring/rotation_scorer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const RotationScorer scorer = RotationScorer();
  final DateTime now = DateTime(2026, 8, 24);

  Garment garment(String id, GarmentCategory category) {
    return Garment(
      id: id,
      name: id,
      category: category,
      photoPaths: const <String>[],
      photoUrls: const <String>[],
    );
  }

  OotdComponentScore score({
    required List<Garment> garments,
    required List<WearLog> logs,
    double baseQuality = 80,
  }) {
    return scorer.score(
      candidate: OutfitCandidate(
        templateType: OotdTemplateType.separated,
        garments: garments,
      ),
      wearLogs: logs,
      now: now,
      baseQuality: baseQuality,
      minimumQualityForBonus: 68,
    );
  }

  WearLog log({
    required String id,
    required String garmentId,
    required DateTime wornDate,
    String? outfitId,
  }) {
    return WearLog(
      id: id,
      memberId: 'member-1',
      garmentId: garmentId,
      wornDate: wornDate,
      outfitId: outfitId,
    );
  }

  group('saved outfit repetition grouping', () {
    test('one saved outfit with several garment rows is grouped correctly', () {
      final List<Garment> garments = <Garment>[
        garment('top-a', GarmentCategory.top),
        garment('bottom-a', GarmentCategory.bottom),
        garment('shoe-a', GarmentCategory.shoe),
      ];

      final OotdComponentScore result = score(
        garments: garments,
        logs: <WearLog>[
          log(
            id: '1',
            garmentId: 'top-a',
            wornDate: DateTime(2026, 8, 14),
            outfitId: 'saved-1',
          ),
          log(
            id: '2',
            garmentId: 'bottom-a',
            wornDate: DateTime(2026, 8, 14),
            outfitId: 'saved-1',
          ),
          log(
            id: '3',
            garmentId: 'shoe-a',
            wornDate: DateTime(2026, 8, 14),
            outfitId: 'saved-1',
          ),
        ],
      );

      expect(result.score, 50);
      expect(
        result.reasons,
        contains('A recently repeated combination was de-prioritized.'),
      );
    });

    test(
      'two different saved outfits worn on the same day remain separate',
      () {
        final List<Garment> garments = <Garment>[
          garment('top-a', GarmentCategory.top),
          garment('bottom-b', GarmentCategory.bottom),
          garment('shoe-a', GarmentCategory.shoe),
        ];

        final OotdComponentScore result = score(
          garments: garments,
          logs: <WearLog>[
            log(
              id: '1',
              garmentId: 'top-a',
              wornDate: DateTime(2026, 8, 14),
              outfitId: 'saved-1',
            ),
            log(
              id: '2',
              garmentId: 'bottom-a',
              wornDate: DateTime(2026, 8, 14),
              outfitId: 'saved-1',
            ),
            log(
              id: '3',
              garmentId: 'shoe-a',
              wornDate: DateTime(2026, 8, 14),
              outfitId: 'saved-1',
            ),
            log(
              id: '4',
              garmentId: 'top-b',
              wornDate: DateTime(2026, 8, 14),
              outfitId: 'saved-2',
            ),
            log(
              id: '5',
              garmentId: 'bottom-b',
              wornDate: DateTime(2026, 8, 14),
              outfitId: 'saved-2',
            ),
            log(
              id: '6',
              garmentId: 'shoe-b',
              wornDate: DateTime(2026, 8, 14),
              outfitId: 'saved-2',
            ),
          ],
        );

        expect(result.score, 70);
        expect(
          result.reasons,
          isNot(
            contains('A recently repeated combination was de-prioritized.'),
          ),
        );
      },
    );

    test(
      'unsaved rows on the same day are not merged as a historical outfit',
      () {
        final List<Garment> garments = <Garment>[
          garment('top-a', GarmentCategory.top),
          garment('bottom-a', GarmentCategory.bottom),
          garment('shoe-a', GarmentCategory.shoe),
        ];

        final OotdComponentScore result = score(
          garments: garments,
          logs: <WearLog>[
            log(id: '1', garmentId: 'top-a', wornDate: DateTime(2026, 8, 23)),
            log(
              id: '2',
              garmentId: 'bottom-a',
              wornDate: DateTime(2026, 8, 23),
            ),
            log(id: '3', garmentId: 'shoe-a', wornDate: DateTime(2026, 8, 23)),
          ],
        );

        expect(result.score, greaterThan(30));
        expect(
          result.reasons,
          isNot(
            contains('A recently repeated combination was de-prioritized.'),
          ),
        );
      },
    );

    test('garment recency still works for unsaved rows', () {
      final OotdComponentScore result = score(
        garments: <Garment>[
          garment('top-a', GarmentCategory.top),
          garment('bottom-a', GarmentCategory.bottom),
          garment('shoe-a', GarmentCategory.shoe),
        ],
        logs: <WearLog>[
          log(id: '1', garmentId: 'top-a', wornDate: DateTime(2026, 8, 23)),
        ],
      );

      expect(result.score, lessThan(78));
      expect(result.score, greaterThan(50));
    });
  });
}
