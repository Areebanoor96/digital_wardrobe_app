import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/outfit.dart';
import 'package:digital_wardrobe_app/data/models/wear_log.dart';
import 'package:digital_wardrobe_app/features/calendar/screens/calendar_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const Size _tallSurface = Size(600, 1600);

GoRouter _router() {
  return GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) =>
            const CalendarScreen(),
      ),
      GoRoute(
        path: '/ootd/plan/:date',
        builder: (BuildContext context, GoRouterState state) =>
            Scaffold(body: Text('PLAN:${state.pathParameters['date']}')),
      ),
    ],
  );
}

Future<void> _pumpCalendar(WidgetTester tester, GoRouter router) async {
  await tester.binding.setSurfaceSize(_tallSurface);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        calendarMonthProvider.overrideWith(
          (Ref ref, DateTime month) async => const <WearLog>[],
        ),
        selectedDayWearHistoryProvider.overrideWith(
          (Ref ref) async => const <WearLog>[],
        ),
        garmentsProvider.overrideWith((Ref ref) async => const <Garment>[]),
        outfitsProvider.overrideWith((Ref ref) async => const <Outfit>[]),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('selecting a day exposes the plan outfit action', (
    WidgetTester tester,
  ) async {
    await _pumpCalendar(tester, _router());

    expect(find.text('Plan outfit for this date'), findsNothing);

    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();

    expect(find.text('September 5, 2026'), findsOneWidget);
    expect(find.text('Plan outfit for this date'), findsOneWidget);
  });

  testWidgets('plan action navigates with the selected date', (
    WidgetTester tester,
  ) async {
    await _pumpCalendar(tester, _router());

    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Plan outfit for this date'));
    await tester.pumpAndSettle();

    expect(find.text('PLAN:2026-09-05'), findsOneWidget);
  });

  testWidgets('month navigation clears the selected day', (
    WidgetTester tester,
  ) async {
    await _pumpCalendar(tester, _router());

    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    expect(find.text('Plan outfit for this date'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(find.text('Plan outfit for this date'), findsNothing);
    expect(find.text('Select a day'), findsOneWidget);

    // Selecting a day in the new month then going back also clears.
    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    expect(find.text('Plan outfit for this date'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    expect(find.text('Plan outfit for this date'), findsNothing);
  });
}
