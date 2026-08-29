import 'package:digital_wardrobe_app/features/wardrobe/models/wardrobe_filters.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/active_filter_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

VoidCallback _noop() => () {};

void main() {
  testWidgets('location chip uses the resolved name after a rename', (
    WidgetTester tester,
  ) async {
    const WardrobeFilters filters = WardrobeFilters(
      locationId: 'loc-1',
      locationName: 'Stale Name',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 60,
            child: ActiveFilterChips(
              filters: filters,
              locationNames: const <String, String>{'loc-1': 'Big Suitcase'},
              onColorRemoved: _noop(),
              onBrandRemoved: _noop(),
              onSizeRemoved: _noop(),
              onOccasionRemoved: _noop(),
              onSeasonRemoved: _noop(),
              onMoodRemoved: _noop(),
              onLaundryStatusRemoved: _noop(),
              onAvailabilityStatusRemoved: _noop(),
              onLocationRemoved: _noop(),
              onStitchingStatusRemoved: _noop(),
              onIroningStatusRemoved: _noop(),
              onOuterwearSubcategoryRemoved: _noop(),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Location: Big Suitcase'), findsOneWidget);
    expect(find.text('Location: Stale Name'), findsNothing);
  });

  testWidgets('location chip falls back to the stored filter name', (
    WidgetTester tester,
  ) async {
    const WardrobeFilters filters = WardrobeFilters(
      locationId: 'loc-1',
      locationName: 'Suitcase',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 60,
            child: ActiveFilterChips(
              filters: filters,
              onColorRemoved: _noop(),
              onBrandRemoved: _noop(),
              onSizeRemoved: _noop(),
              onOccasionRemoved: _noop(),
              onSeasonRemoved: _noop(),
              onMoodRemoved: _noop(),
              onLaundryStatusRemoved: _noop(),
              onAvailabilityStatusRemoved: _noop(),
              onLocationRemoved: _noop(),
              onStitchingStatusRemoved: _noop(),
              onIroningStatusRemoved: _noop(),
              onOuterwearSubcategoryRemoved: _noop(),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Location: Suitcase'), findsOneWidget);
  });
}