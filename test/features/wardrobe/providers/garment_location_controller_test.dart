import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/garment_location.dart';
import 'package:digital_wardrobe_app/data/repositories/garment_location_repository.dart';
import 'package:digital_wardrobe_app/data/repositories/garment_repository.dart';
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
      name: 'Audit Cupboard',
    ),
  ];

  int createCalls = 0;
  int renameCalls = 0;
  final List<String> renamedTo = <String>[];

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

class _FakeGarmentRepository extends GarmentRepository {
  _FakeGarmentRepository()
    : super(
        SupabaseClient(
          'https://example.supabase.co',
          'anon-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );

  final Map<String, int> fetchGarmentCalls = <String, int>{};

  @override
  Future<Garment> fetchGarment({
    required String id,
    required String memberId,
  }) async {
    fetchGarmentCalls[id] = (fetchGarmentCalls[id] ?? 0) + 1;
    return Garment(
      id: id,
      name: 'Garment $id',
      memberId: memberId,
      category: GarmentCategory.top,
      photoPaths: const <String>[],
      photoUrls: const <String>[],
      locationId: 'loc-1',
      locationName: 'Suitcase',
    );
  }
}

Garment garmentWithLocation(String id, String locationId) {
  return Garment(
    id: id,
    name: 'Garment $id',
    memberId: _member.id,
    category: GarmentCategory.top,
    photoPaths: const <String>[],
    photoUrls: const <String>[],
    locationId: locationId,
    locationName: locationId == 'loc-1' ? 'Suitcase' : 'Audit Cupboard',
  );
}

void main() {
  test('create with an existing location name is rejected up front', () async {
    final _FakeLocationRepository repository = _FakeLocationRepository();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        selectedFamilyMemberProvider.overrideWith((Ref ref) => _member),
        garmentLocationRepositoryProvider.overrideWith(
          (Ref ref) => repository,
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(garmentLocationsProvider.future);

    await container
        .read(garmentLocationControllerProvider.notifier)
        .create(name: ' suitcase ');

    final AsyncValue<void> state = container.read(
      garmentLocationControllerProvider,
    );

    expect(state.hasError, isTrue);
    expect(state.error, isA<LocationNameConflict>());
    expect(repository.createCalls, 0);
  });

  test('rename to an existing location name is rejected up front', () async {
    final _FakeLocationRepository repository = _FakeLocationRepository();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        selectedFamilyMemberProvider.overrideWith((Ref ref) => _member),
        garmentLocationRepositoryProvider.overrideWith(
          (Ref ref) => repository,
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(garmentLocationsProvider.future);

    await container
        .read(garmentLocationControllerProvider.notifier)
        .rename(locationId: 'loc-1', name: 'Audit Cupboard');

    final AsyncValue<void> state = container.read(
      garmentLocationControllerProvider,
    );

    expect(state.hasError, isTrue);
    expect(state.error, isA<LocationNameConflict>());
    expect(repository.renameCalls, 0);
  });

  test('rename to its own name is allowed', () async {
    final _FakeLocationRepository repository = _FakeLocationRepository();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        selectedFamilyMemberProvider.overrideWith((Ref ref) => _member),
        garmentLocationRepositoryProvider.overrideWith(
          (Ref ref) => repository,
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(garmentLocationsProvider.future);

    await container
        .read(garmentLocationControllerProvider.notifier)
        .rename(locationId: 'loc-1', name: 'Suitcase');

    final AsyncValue<void> state = container.read(
      garmentLocationControllerProvider,
    );

    expect(state.hasError, isFalse);
    expect(repository.renameCalls, 1);
    expect(repository.renamedTo, <String>['Suitcase']);
  });

  test('rename invalidates garmentProvider for garments using it', () async {
    final _FakeLocationRepository repository = _FakeLocationRepository();
    final _FakeGarmentRepository garmentRepository = _FakeGarmentRepository();

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        selectedFamilyMemberProvider.overrideWith((Ref ref) => _member),
        garmentLocationRepositoryProvider.overrideWith(
          (Ref ref) => repository,
        ),
        garmentRepositoryProvider.overrideWith((Ref ref) => garmentRepository),
        garmentsProvider.overrideWith(
          (Ref ref) async => <Garment>[
            garmentWithLocation('g-1', 'loc-1'),
            garmentWithLocation('g-2', 'loc-2'),
          ],
        ),
        archivedGarmentsProvider.overrideWith(
          (Ref ref) async => <Garment>[
            garmentWithLocation('g-3', 'loc-1'),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(garmentLocationsProvider.future);
    await container.read(garmentsProvider.future);
    await container.read(archivedGarmentsProvider.future);

    await container.read(garmentProvider('g-1').future);
    await container.read(garmentProvider('g-2').future);
    await container.read(garmentProvider('g-3').future);

    await container
        .read(garmentLocationControllerProvider.notifier)
        .rename(locationId: 'loc-1', name: 'Big Suitcase');

    final AsyncValue<void> state = container.read(
      garmentLocationControllerProvider,
    );
    expect(state.hasError, isFalse);

    // Open details are refetched so the renamed location name is picked up.
    await container.read(garmentProvider('g-1').future);
    await container.read(garmentProvider('g-2').future);
    await container.read(garmentProvider('g-3').future);

    expect(garmentRepository.fetchGarmentCalls['g-1'], 2);
    expect(garmentRepository.fetchGarmentCalls['g-2'], 1);
    expect(garmentRepository.fetchGarmentCalls['g-3'], 2);
  });
}