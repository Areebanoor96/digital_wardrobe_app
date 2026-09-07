import 'dart:async';

import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/analytics.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/outfit.dart';
import 'package:digital_wardrobe_app/data/models/profile.dart';
import 'package:digital_wardrobe_app/data/models/wear_log.dart';
import 'package:digital_wardrobe_app/features/analytics/screens/analytics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const AnalyticsSummary _plainSummary = AnalyticsSummary(
  totalGarments: 2,
  activeGarments: 2,
  archivedGarments: 0,
  totalWears: 0,
);

const Profile _pkProfile = Profile(id: 'user-1', countryCode: 'PK');

Garment _garment(String id, String name, GarmentCategory category) {
  return Garment(
    id: id,
    name: name,
    category: category,
    photoPaths: const <String>[],
    photoUrls: const <String>[],
  );
}

WearLog _log(String id, String garmentId, DateTime wornDate,
    {String? eventName}) {
  return WearLog(
    id: id,
    memberId: 'member-1',
    garmentId: garmentId,
    wornDate: wornDate,
    eventName: eventName,
  );
}

Outfit _outfit(
  String id,
  String name, {
  required int timesWorn,
  DateTime? lastWornDate,
}) {
  return Outfit(
    id: id,
    garmentIds: const <String>['g-1'],
    memberId: 'member-1',
    name: name,
    timesWorn: timesWorn,
    lastWornDate: lastWornDate,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  double width = 500,
  AnalyticsSummary summary = _plainSummary,
  List<WearLog> wearLogs = const <WearLog>[],
  List<Garment> garments = const <Garment>[],
  List<Outfit> outfits = const <Outfit>[],
  List<Override>? extraOverrides,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        analyticsSummaryProvider.overrideWith((ref) async => summary),
        profileProvider.overrideWith((ref) async => _pkProfile),
        recentWearActivityProvider.overrideWith(
          (ref) async => wearLogs,
        ),
        garmentsProvider.overrideWith((ref) async => garments),
        outfitsProvider.overrideWith((ref) async => outfits),
        ...?extraOverrides,
      ],
      child: const MaterialApp(home: AnalyticsScreen(canNavigateBack: false)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Wear activity', () {
    testWidgets('displays recent wears with garment names and images', (
      tester,
    ) async {
      await _pump(
        tester,
        wearLogs: <WearLog>[
          _log(
            'wl-1',
            'g-1',
            DateTime.now().subtract(const Duration(days: 1)),
          ),
          _log(
            'wl-2',
            'g-2',
            DateTime.now().subtract(const Duration(days: 3)),
            eventName: 'Office',
          ),
        ],
        garments: <Garment>[
          _garment('g-1', 'Blue Shirt', GarmentCategory.top),
          _garment('g-2', 'Chunky Sneakers', GarmentCategory.shoe),
        ],
      );

      expect(find.text('Wear activity'), findsOneWidget);
      expect(find.text('Latest 2 wears'), findsOneWidget);
      expect(find.text('Blue Shirt'), findsOneWidget);
      expect(find.text('Chunky Sneakers'), findsOneWidget);
      expect(find.text('Shoes · Office'), findsOneWidget);
    });

    testWidgets('shows relative dates for recent activity', (tester) async {
      final DateTime now = DateTime.now();
      await _pump(
        tester,
        wearLogs: <WearLog>[
          _log('wl-1', 'g-1', now),
          _log('wl-2', 'g-2', now.subtract(const Duration(days: 1))),
        ],
        garments: <Garment>[
          _garment('g-1', 'Blue Shirt', GarmentCategory.top),
          _garment('g-2', 'Chunky Sneakers', GarmentCategory.shoe),
        ],
      );

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
    });

    testWidgets('renders an empty state when there is no activity', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('No wear activity yet'), findsOneWidget);
      expect(
        find.text(
          'Wear activity will appear here as you log wears for your garments.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders an error state with retry when activity fails', (
      tester,
    ) async {
      await _pump(
        tester,
        extraOverrides: <Override>[
          recentWearActivityProvider.overrideWith(
            (ref) => Future<List<WearLog>>.error(StateError('boom')),
          ),
        ],
      );

      expect(find.text('We could not load wear activity'), findsOneWidget);
      expect(find.text('Retry'), findsWidgets);
    });

    testWidgets('renders loading state while activity loads', (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            analyticsSummaryProvider.overrideWith(
              (ref) async => _plainSummary,
            ),
            profileProvider.overrideWith((ref) async => _pkProfile),
            recentWearActivityProvider.overrideWith(
              (ref) => Completer<List<WearLog>>().future,
            ),
            garmentsProvider.overrideWith(
              (ref) async => const <Garment>[],
            ),
            outfitsProvider.overrideWith(
              (ref) async => const <Outfit>[],
            ),
          ],
          child: const MaterialApp(home: AnalyticsScreen(canNavigateBack: false)),
        ),
      );
      await tester.pump();

      expect(find.text('Loading wear activity…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('long garment names do not overflow on a narrow screen', (
      tester,
    ) async {
      final String longName =
          'A Very Long Garment Name That Should Never Overflow The Tile '
          'Even On A Narrow Phone Screen';
      await _pump(
        tester,
        width: 320,
        wearLogs: <WearLog>[
          _log('wl-1', 'g-1', DateTime.now()),
        ],
        garments: <Garment>[
          _garment('g-1', longName, GarmentCategory.top),
        ],
      );

      expect(find.text(longName), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Outfit insights', () {
    testWidgets('displays outfit metrics from real data', (tester) async {
      await _pump(
        tester,
        outfits: <Outfit>[
          _outfit('o-1', 'Business Look', timesWorn: 8, lastWornDate: DateTime
              .now()
              .subtract(const Duration(days: 1))),
          _outfit('o-2', 'Gym Set', timesWorn: 3),
          _outfit('o-3', 'Date Night', timesWorn: 0),
        ],
      );

      expect(find.text('Outfit insights'), findsOneWidget);
      expect(find.text('3 saved outfits'), findsOneWidget);
      expect(find.text('Business Look'), findsOneWidget);
      expect(find.text('8 wears'), findsOneWidget);
      expect(find.text('Last outfit worn'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('Never worn'), findsOneWidget);
      expect(find.text('1 of 3'), findsOneWidget);
    });

    testWidgets('most-used outfit displays correctly', (tester) async {
      await _pump(
        tester,
        outfits: <Outfit>[
          _outfit('o-1', 'Everyday Jeans', timesWorn: 12, lastWornDate: DateTime
              .now()),
          _outfit('o-2', 'Party Dress', timesWorn: 4),
        ],
      );

      expect(find.text('Most worn outfit'), findsOneWidget);
      expect(find.text('Everyday Jeans'), findsOneWidget);
      expect(find.text('12 wears'), findsOneWidget);
    });

    testWidgets('lists recently worn outfits', (tester) async {
      final DateTime now = DateTime.now();
      await _pump(
        tester,
        outfits: <Outfit>[
          _outfit(
            'o-1',
            'Morning Run',
            timesWorn: 6,
            lastWornDate: now,
          ),
          _outfit(
            'o-2',
            'Friday Special',
            timesWorn: 2,
            lastWornDate: now.subtract(const Duration(days: 1)),
          ),
          _outfit(
            'o-3',
            'Weekend Look',
            timesWorn: 1,
            lastWornDate: now.subtract(const Duration(days: 2)),
          ),
        ],
      );

      expect(find.text('Worn Today'), findsOneWidget);
      expect(find.text('Worn Yesterday'), findsOneWidget);
      expect(find.text('Weekend Look'), findsOneWidget);
    });

    testWidgets('renders an empty state when no outfits are saved', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('No outfit insights yet'), findsOneWidget);
    });

    testWidgets('renders loading state while outfits load', (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            analyticsSummaryProvider.overrideWith(
              (ref) async => _plainSummary,
            ),
            profileProvider.overrideWith((ref) async => _pkProfile),
            recentWearActivityProvider.overrideWith(
              (ref) async => const <WearLog>[],
            ),
            garmentsProvider.overrideWith(
              (ref) async => const <Garment>[],
            ),
            outfitsProvider.overrideWith(
              (ref) => Completer<List<Outfit>>().future,
            ),
          ],
          child: const MaterialApp(home: AnalyticsScreen(canNavigateBack: false)),
        ),
      );
      await tester.pump();

      expect(find.text('Loading outfit insights…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });
  });

  group('Integration with Step 1 metrics', () {
    testWidgets('existing Step 1 sections still render', (tester) async {
      await _pump(
        tester,
        summary: const AnalyticsSummary(
          totalGarments: 5,
          activeGarments: 4,
          archivedGarments: 1,
          totalWears: 20,
          totalValue: 125000,
          mostWornName: 'Blue Shirt',
          mostWornCount: 12,
          leastWornName: 'Black Tie',
          leastWornCount: 1,
          categoryDistribution: <String, int>{
            'Tops': 3,
            'Bottoms': 1,
          },
        ),
        wearLogs: <WearLog>[
          _log('wl-1', 'g-1', DateTime.now()),
        ],
        garments: <Garment>[
          _garment('g-1', 'Blue Shirt', GarmentCategory.top),
        ],
        outfits: <Outfit>[
          _outfit('o-1', 'Business Look', timesWorn: 2, lastWornDate: DateTime
              .now()),
        ],
      );

      expect(find.text('Total garments'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Category breakdown'), findsOneWidget);
      expect(find.text('Garment usage'), findsOneWidget);
      expect(find.text('Blue Shirt'), findsWidgets);
      expect(find.text('Usage insights'), findsOneWidget);
      expect(find.text('Wear activity'), findsOneWidget);
      expect(find.text('Outfit insights'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}