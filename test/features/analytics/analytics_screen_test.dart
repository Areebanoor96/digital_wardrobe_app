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
}) async {
  await tester.binding.setSurfaceSize(Size(width, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final AnalyticsSummary summary = AnalyticsSummary(
    totalGarments: 5,
    activeGarments: 4,
    archivedGarments: 1,
    totalWears: 20,
    totalValue: value,
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        analyticsSummaryProvider.overrideWith((ref) async => summary),
        profileProvider.overrideWith((ref) async => profile),
      ],
      child: const MaterialApp(home: AnalyticsScreen(canNavigateBack: false)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('wardrobe value uses PKR for a Pakistan country', (tester) async {
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

  testWidgets('Wardrobe Value card does not overflow on a narrow screen', (
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

  testWidgets('Wardrobe Value card does not overflow with a large value', (
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
}