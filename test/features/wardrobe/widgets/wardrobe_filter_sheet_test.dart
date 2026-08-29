import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/garment_location.dart';
import 'package:digital_wardrobe_app/features/wardrobe/providers/wardrobe_filter_provider.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/wardrobe_filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Garment garment({
  required String id,
  String? locationId,
  String? locationName,
}) {
  return Garment(
    id: id,
    name: 'Garment $id',
    memberId: 'member-1',
    category: GarmentCategory.top,
    photoPaths: const <String>[],
    photoUrls: const <String>[],
    locationId: locationId,
    locationName: locationName,
  );
}

const List<GarmentLocation> _locations = <GarmentLocation>[
  GarmentLocation(id: 'loc-used', userId: 'u', memberId: 'm', name: 'Suitcase'),
  GarmentLocation(id: 'loc-empty', userId: 'u', memberId: 'm', name: 'Attic'),
];

Future<ProviderContainer> pumpSheet(
  WidgetTester tester, {
  List<Garment> garments = const <Garment>[],
  String? presetLocationId,
  String? presetLocationName,
}) async {
  tester.view.physicalSize = const Size(900, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      garmentLocationsProvider.overrideWith((Ref ref) async => _locations),
    ],
  );
  addTearDown(container.dispose);

  if (presetLocationId != null) {
    container
        .read(wardrobeFilterProvider.notifier)
        .setLocation(id: presetLocationId, name: presetLocationName);
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(body: WardrobeFilterSheet(garments: garments)),
      ),
    ),
  );
  await tester.pump();

  return container;
}

void main() {
  testWidgets(
    'location options come from garmentLocationsProvider, '
    'including locations with no active garments',
    (WidgetTester tester) async {
      await pumpSheet(
        tester,
        garments: <Garment>[
          garment(
            id: 'g-1',
            locationId: 'loc-used',
            locationName: 'Suitcase',
          ),
        ],
      );

      await tester.tap(find.text('All locations'));
      await tester.pumpAndSettle();

      expect(find.text('Attic'), findsOneWidget);
      expect(find.text('Suitcase'), findsWidgets);
    },
  );

  testWidgets('selecting a location with no active garments sets the filter', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpSheet(
      tester,
      garments: <Garment>[
        garment(id: 'g-1', locationId: 'loc-used', locationName: 'Suitcase'),
      ],
    );

    await tester.tap(find.text('All locations'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Attic').last);
    await tester.pumpAndSettle();

    expect(container.read(wardrobeFilterProvider).locationId, 'loc-empty');
    expect(container.read(wardrobeFilterProvider).locationName, 'Attic');
  });

  testWidgets('a stale selected location does not cause a dropdown assertion', (
    WidgetTester tester,
  ) async {
    await pumpSheet(
      tester,
      garments: <Garment>[garment(id: 'g-1')],
      presetLocationId: 'stale-location',
      presetLocationName: 'Gone Basket',
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('All locations'), findsWidgets);
  });
}