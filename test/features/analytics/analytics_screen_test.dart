import 'dart:async';

import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/analytics.dart';
import 'package:digital_wardrobe_app/data/models/profile.dart';
import 'package:digital_wardrobe_app/features/analytics/screens/analytics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  required Profile profile,
  double width = 500,
  double value = 125000,
  AnalyticsSummary? summary,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final AnalyticsSummary effectiveSummary = summary ??
      AnalyticsSummary(
        totalGarments: 5,
        activeGarments: 4,
        archivedGarments: 1,
        totalWears: 20,
        totalValue: value,
        mostWornName: 'Blue Shirt',
        mostWornCount: 12,
        leastWornName: 'Black Tie',
        leastWornCount: 1,
        categoryDistribution: const <String, int>{
          'Tops': 3,
          'Bottoms': 1,
          'Accessories': 1,
        },
        wearDistribution: const <String, int>{
          'Never worn': 1,
          '1–5 wears': 2,
          '6–15 wears': 1,
          '16+ wears': 1,
        },
      );

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        analyticsSummaryProvider.overrideWith((ref) async => effectiveSummary),
        profileProvider.overrideWith((ref) async => profile),
      ],
      child: const MaterialApp(home: AnalyticsScreen(canNavigateBack: false)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Analytics screen renders', () {
    testWidgets('displays the app bar title', (tester) async {
      await _pump(
        tester,
        profile: const Profile(id: 'user-1', countryCode: 'PK'),
      );

      expect(find.text('Analytics'), findsOneWidget);
    });

    testWidgets('displays key metric cards', (tester) async {
      await _pump(
        tester,
        profile: const Profile(id: 'user-1', countryCode: 'PK'),
      );

      expect(find.text('Total garments'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('Total wears'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
    });

    testWidgets('displays category breakdown section', (tester) async {
      await _pump(
        tester,
        profile: const Profile(id: 'user-1', countryCode: 'PK'),
      );

      expect(find.text('Category breakdown'), findsOneWidget);
      expect(find.text('Tops'), findsOneWidget);
      expect(find.text('Bottoms'), findsOneWidget);
    });

    testWidgets('displays garment usage section', (tester) async {
      await _pump(
        tester,
        profile: const Profile(id: 'user-1', countryCode: 'PK'),
      );

      expect(find.text('Garment usage'), findsOneWidget);
      expect(find.text('Blue Shirt'), findsOneWidget);
      expect(find.text('Black Tie'), findsOneWidget);
      expect(find.text('Most worn'), findsOneWidget);
      expect(find.text('Least worn'), findsOneWidget);
    });

    testWidgets('displays usage insights section', (tester) async {
      await _pump(
        tester,
        profile: const Profile(id: 'user-1', countryCode: 'PK'),
      );

      expect(find.text('Usage insights'), findsOneWidget);
      expect(find.text('Avg cost per wear'), findsOneWidget);
      expect(find.text('Never worn'), findsWidgets);
      expect(find.text('Utilization'), findsOneWidget);
    });
  });

  group('Currency formatting', () {
    testWidgets('wardrobe value uses PKR for a Pakistan country', (
      tester,
    ) async {
      await _pump(
        tester,
        profile: const Profile(id: 'user-1', countryCode: 'PK'),
      );

      expect(find.text('PKR 125,000'), findsOneWidget);
    });

    testWidgets('wardrobe value uses USD for a United States country', (
      tester,
    ) async {
      await _pump(
        tester,
        profile: const Profile(id: 'user-1', countryCode: 'US'),
      );

      expect(find.text('USD 125,000'), findsOneWidget);
    });

    testWidgets('wardrobe value uses GBP for a United Kingdom country', (
      tester,
    ) async {
      await _pump(
        tester,
        profile: const Profile(id: 'user-1', countryCode: 'GB'),
      );

      expect(find.text('GBP 125,000'), findsOneWidget);
    });

    testWidgets('missing country falls back to PKR without crashing', (
      tester,
    ) async {
      await _pump(
        tester,
        profile: const Profile(id: 'user-1'),
      );

      expect(find.text('PKR 125,000'), findsOneWidget);
    });
  });

  group('Responsive layout', () {
    testWidgets('metric cards do not overflow on a narrow screen', (
      tester,
    ) async {
      await _pump(
        tester,
        profile: const Profile(id: 'user-1', countryCode: 'US'),
        width: 320,
        value: 125000,
      );

      expect(find.text('USD 125,000'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('metric cards do not overflow with a large value', (
      tester,
    ) async {
      await _pump(
        tester,
        profile: const Profile(id: 'user-1', countryCode: 'PK'),
        width: 360,
        value: 12500000,
      );

      expect(find.text('PKR 12,500,000'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('metric cards do not overflow on a very narrow screen', (
      tester,
    ) async {
      await _pump(
        tester,
        profile: const Profile(id: 'user-1', countryCode: 'PK'),
        width: 280,
      );

      expect(find.text('Total garments'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Loading state', () {
    testWidgets('shows loading indicator while data loads', (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            analyticsSummaryProvider.overrideWith(
              (ref) => Completer<AnalyticsSummary>().future,
            ),
            profileProvider.overrideWith(
              (ref) async => const Profile(id: 'user-1'),
            ),
          ],
          child: const MaterialApp(
            home: AnalyticsScreen(canNavigateBack: false),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading insights…'), findsOneWidget);
    });
  });

  group('Empty state', () {
    testWidgets('shows empty state when no wardrobe data', (tester) async {
      await _pump(
        tester,
        profile: const Profile(id: 'user-1'),
        summary: const AnalyticsSummary(
          totalGarments: 0,
          activeGarments: 0,
          archivedGarments: 0,
          totalWears: 0,
        ),
      );

      expect(find.text('No wardrobe data yet'), findsOneWidget);
      expect(
        find.text(
          'Add garments and record wears to see your insights here.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.insights_outlined), findsOneWidget);
    });

    testWidgets('does not show empty state when garments exist', (
      tester,
    ) async {
      await _pump(
        tester,
        profile: const Profile(id: 'user-1', countryCode: 'PK'),
      );

      expect(find.text('No wardrobe data yet'), findsNothing);
      expect(find.text('Total garments'), findsOneWidget);
    });
  });

  group('Real data display', () {
    testWidgets('displays correct metric values', (tester) async {
      await _pump(
        tester,
        profile: const Profile(id: 'user-1', countryCode: 'PK'),
        summary: const AnalyticsSummary(
          totalGarments: 15,
          activeGarments: 12,
          archivedGarments: 3,
          totalWears: 47,
          totalValue: 85000,
          mostWornName: 'White Sneakers',
          mostWornCount: 25,
          leastWornName: 'Bow Tie',
          leastWornCount: 1,
          categoryDistribution: <String, int>{
            'Tops': 5,
            'Bottoms': 4,
            'Shoes': 3,
          },
          wearDistribution: <String, int>{
            'Never worn': 3,
            '1–5 wears': 5,
            '6–15 wears': 2,
            '16+ wears': 2,
          },
        ),
      );

      expect(find.text('15'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('47'), findsOneWidget);
      expect(find.text('3'), findsWidgets);
      expect(find.text('White Sneakers'), findsOneWidget);
      expect(find.text('25 wears'), findsWidgets);
      expect(find.text('Bow Tie'), findsOneWidget);
      expect(find.text('1 wears'), findsWidgets);
    });

    testWidgets('hides Closet Vault when no archived garments', (
      tester,
    ) async {
      await _pump(
        tester,
        profile: const Profile(id: 'user-1'),
        summary: const AnalyticsSummary(
          totalGarments: 5,
          activeGarments: 5,
          archivedGarments: 0,
          totalWears: 10,
        ),
      );

      expect(find.text('Closet Vault'), findsNothing);
    });

    testWidgets('shows Closet Vault when archived garments exist', (
      tester,
    ) async {
      await _pump(
        tester,
        profile: const Profile(id: 'user-1'),
      );

      expect(find.text('Closet Vault'), findsOneWidget);
    });

    testWidgets('hides usage insights when no wears recorded', (
      tester,
    ) async {
      await _pump(
        tester,
        profile: const Profile(id: 'user-1'),
        summary: const AnalyticsSummary(
          totalGarments: 5,
          activeGarments: 5,
          archivedGarments: 0,
          totalWears: 0,
          mostWornName: 'Blue Shirt',
          mostWornCount: 0,
        ),
      );

      expect(find.text('Usage insights'), findsNothing);
    });

    testWidgets('hides garment usage when no wear data', (tester) async {
      await _pump(
        tester,
        profile: const Profile(id: 'user-1'),
        summary: const AnalyticsSummary(
          totalGarments: 5,
          activeGarments: 5,
          archivedGarments: 0,
          totalWears: 0,
        ),
      );

      expect(find.text('Garment usage'), findsNothing);
    });

    testWidgets('hides category breakdown when empty', (tester) async {
      await _pump(
        tester,
        profile: const Profile(id: 'user-1'),
        summary: const AnalyticsSummary(
          totalGarments: 5,
          activeGarments: 5,
          archivedGarments: 0,
          totalWears: 10,
        ),
      );

      expect(find.text('Category breakdown'), findsNothing);
    });

    testWidgets('shows average wears per garment when positive', (
      tester,
    ) async {
      await _pump(
        tester,
        profile: const Profile(id: 'user-1'),
        summary: const AnalyticsSummary(
          totalGarments: 10,
          activeGarments: 10,
          archivedGarments: 0,
          totalWears: 30,
        ),
      );

      expect(find.text('Avg wears per garment'), findsOneWidget);
      expect(find.text('3.0'), findsOneWidget);
    });

    testWidgets('shows avg cost per wear when value and wears exist', (
      tester,
    ) async {
      await _pump(
        tester,
        profile: const Profile(id: 'user-1', countryCode: 'PK'),
        summary: const AnalyticsSummary(
          totalGarments: 5,
          activeGarments: 5,
          archivedGarments: 0,
          totalWears: 10,
          totalValue: 50000,
        ),
      );

      expect(find.text('Avg cost per wear'), findsOneWidget);
      expect(find.text('PKR 5,000'), findsOneWidget);
    });
  });

  group('Navigation', () {
    testWidgets('shows back arrow when canNavigateBack is true', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(500, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            analyticsSummaryProvider.overrideWith(
              (ref) async => const AnalyticsSummary(
                totalGarments: 0,
                activeGarments: 0,
                archivedGarments: 0,
                totalWears: 0,
              ),
            ),
            profileProvider.overrideWith(
              (ref) async => const Profile(id: 'user-1'),
            ),
          ],
          child: MaterialApp(
            home: AnalyticsScreen(
              canNavigateBack: true,
              onNavigateBack: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('hides back arrow when canNavigateBack is false', (
      tester,
    ) async {
      await _pump(
        tester,
        profile: const Profile(id: 'user-1'),
      );

      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });
  });
}
