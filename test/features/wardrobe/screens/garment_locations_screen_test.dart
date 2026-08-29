import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/data/models/garment_location.dart';
import 'package:digital_wardrobe_app/data/repositories/garment_location_repository.dart';
import 'package:digital_wardrobe_app/features/wardrobe/screens/garment_locations_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const FamilyMember _member = FamilyMember(
  id: 'member-1',
  name: 'Ava',
  relationship: RelationshipType.child,
);

class _FakeLocationRepository extends GarmentLocationRepository {
  _FakeLocationRepository()
    : super(
        SupabaseClient(
          'https://example.supabase.co',
          'anon-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );

  int createCalls = 0;
  int renameCalls = 0;
  final List<String> renamedTo = <String>[];

  final List<GarmentLocation> locations = <GarmentLocation>[
    const GarmentLocation(
      id: 'loc-1',
      userId: 'user-1',
      memberId: 'member-1',
      name: 'Suitcase',
    ),
    const GarmentLocation(
      id: 'loc-2',
      userId: 'user-1',
      memberId: 'member-1',
      name: 'Winter Storage Bag',
    ),
    const GarmentLocation(
      id: 'loc-3',
      userId: 'user-1',
      memberId: 'member-1',
      name: 'Blue Suitcase',
    ),
  ];

  @override
  Future<List<GarmentLocation>> fetchLocations({
    required String memberId,
  }) async {
    return locations;
  }

  @override
  Future<GarmentLocation> createLocation({
    required String memberId,
    required String name,
  }) async {
    createCalls++;
    final GarmentLocation location = GarmentLocation(
      id: 'loc-${locations.length + 1}',
      userId: 'user-1',
      memberId: memberId,
      name: name.trim(),
    );
    locations.add(location);
    return location;
  }

  @override
  Future<void> renameLocation({
    required String memberId,
    required String locationId,
    required String name,
  }) async {
    renameCalls++;
    renamedTo.add(name.trim());
    final int index = locations.indexWhere(
      (GarmentLocation location) => location.id == locationId,
    );
    if (index >= 0) {
      locations.removeAt(index);
      locations.insert(
        index,
        GarmentLocation(
          id: locationId,
          userId: 'user-1',
          memberId: memberId,
          name: name.trim(),
        ),
      );
    }
  }
}

Future<_FakeLocationRepository> _pumpScreen(WidgetTester tester) async {
  final _FakeLocationRepository repository = _FakeLocationRepository();

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        selectedFamilyMemberProvider.overrideWith((Ref ref) => _member),
        garmentLocationRepositoryProvider.overrideWith(
          (Ref ref) => repository,
        ),
      ],
      child: const MaterialApp(home: GarmentLocationsScreen()),
    ),
  );
  await tester.pumpAndSettle();

  return repository;
}

void main() {
  testWidgets('creating a duplicate location shows a clear message', (
    WidgetTester tester,
  ) async {
    final _FakeLocationRepository repository = await _pumpScreen(tester);

    await tester.tap(find.text('Add Location').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Location Name'),
      'Suitcase',
    );
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(
      find.text('A location named "Suitcase" already exists.'),
      findsOneWidget,
    );
    expect(repository.createCalls, 0);
  });

  testWidgets('renaming to a duplicate location shows a clear message', (
    WidgetTester tester,
  ) async {
    final _FakeLocationRepository repository = await _pumpScreen(tester);

    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Location Name'),
      'blue suitcase',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(
      find.text('A location named "blue suitcase" already exists.'),
      findsOneWidget,
    );
    expect(repository.renameCalls, 0);
  });

  testWidgets('renaming a location succeeds and updates the list', (
    WidgetTester tester,
  ) async {
    final _FakeLocationRepository repository = await _pumpScreen(tester);

    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Location Name'),
      'Almirah',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repository.renameCalls, 1);
    expect(repository.renamedTo, <String>['Almirah']);
    expect(find.text('Location renamed.'), findsOneWidget);
  });
}