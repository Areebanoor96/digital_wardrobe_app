import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/wardrobe/models/wardrobe_filters.dart';
import 'package:digital_wardrobe_app/features/wardrobe/providers/wardrobe_filter_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Garment garment({
  required String id,
  String? colorName,
  String? colorHex,
  List<GarmentColorShade> colorShades = const <GarmentColorShade>[],
  List<String> sizes = const <String>[],
  GarmentAvailabilityStatus availabilityStatus =
      GarmentAvailabilityStatus.available,
  String? locationId,
  String? locationName,
  StitchingStatus? stitchingStatus,
  IroningStatus? ironingStatus,
  GarmentCategory category = GarmentCategory.top,
  String? subcategory,
}) {
  return Garment(
    id: id,
    name: 'Garment $id',
    memberId: 'member-1',
    category: category,
    photoPaths: const <String>['test/photo.jpg'],
    photoUrls: const <String>[],
    subcategory: subcategory,
    colorName: colorName,
    colorHex: colorHex,
    colorShades: colorShades,
    sizes: sizes,
    availabilityStatus: availabilityStatus,
    locationId: locationId,
    locationName: locationName,
    stitchingStatus: stitchingStatus,
    ironingStatus: ironingStatus,
  );
}

void main() {
  test('default and reset sort option is Least Worn', () {
    final WardrobeFilterNotifier notifier = WardrobeFilterNotifier();

    expect(notifier.state.sortOption, WardrobeSortOption.leastWorn);

    notifier.setSortOption(WardrobeSortOption.mostWorn);
    notifier.clearAll();

    expect(notifier.state.sortOption, WardrobeSortOption.leastWorn);
  });

  testWidgets('color filtering still matches palette and legacy colors', (
    WidgetTester tester,
  ) async {
    final List<Garment> garments = <Garment>[
      garment(id: 'palette', colorName: 'Navy', colorHex: '#000080'),
      garment(
        id: 'multi',
        colorName: 'Burgundy',
        colorHex: '#800020',
        colorShades: const <GarmentColorShade>[
          GarmentColorShade(
            name: 'Burgundy',
            hex: '#800020',
            isPrimary: true,
          ),
          GarmentColorShade(name: 'Navy', hex: '#000080'),
        ],
      ),
      garment(id: 'legacy', colorName: 'navy'),
      garment(id: 'other', colorName: 'Red', colorHex: '#D22B2B'),
      garment(id: 'no-color'),
    ];

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        garmentsProvider.overrideWith((Ref ref) async => garments),
      ],
    );

    addTearDown(container.dispose);

    // Warm the garments provider before applying the filter.
    await container.read(garmentsProvider.future);

    container
        .read(wardrobeFilterProvider.notifier)
        .setColor('Navy');

    final List<Garment> filtered = container.read(filteredGarmentsProvider);

    expect(filtered.map((Garment garment) => garment.id), <String>[
      'palette',
      'multi',
      'legacy',
    ]);
  });

  testWidgets('filters normalized sizes and garment management fields', (
    WidgetTester tester,
  ) async {
    final List<Garment> garments = <Garment>[
      garment(
        id: 'match',
        sizes: const <String>['S', 'M'],
        availabilityStatus: GarmentAvailabilityStatus.borrowed,
        locationId: 'location-1',
        locationName: 'Suitcase',
        stitchingStatus: StitchingStatus.stitched,
        ironingStatus: IroningStatus.ironed,
        category: GarmentCategory.outerwear,
        subcategory: 'Coat',
      ),
      garment(
        id: 'wrong-status',
        sizes: const <String>['M'],
        availabilityStatus: GarmentAvailabilityStatus.lent,
        locationId: 'location-1',
        locationName: 'Suitcase',
        stitchingStatus: StitchingStatus.stitched,
        ironingStatus: IroningStatus.ironed,
        category: GarmentCategory.outerwear,
        subcategory: 'Coat',
      ),
      garment(
        id: 'wrong-location',
        sizes: const <String>['M'],
        availabilityStatus: GarmentAvailabilityStatus.borrowed,
        locationId: 'location-2',
        locationName: 'Drawer',
        stitchingStatus: StitchingStatus.stitched,
        ironingStatus: IroningStatus.ironed,
        category: GarmentCategory.outerwear,
        subcategory: 'Coat',
      ),
      garment(id: 'wrong-size', sizes: const <String>['L']),
    ];

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        garmentsProvider.overrideWith((Ref ref) async => garments),
      ],
    );

    addTearDown(container.dispose);

    await container.read(garmentsProvider.future);

    final WardrobeFilterNotifier notifier = container.read(
      wardrobeFilterProvider.notifier,
    );
    notifier.setSize('M');
    notifier.setAvailabilityStatus(GarmentAvailabilityStatus.borrowed);
    notifier.setLocation(id: 'location-1', name: 'Suitcase');
    notifier.setStitchingStatus(StitchingStatus.stitched);
    notifier.setIroningStatus(IroningStatus.ironed);
    notifier.setOuterwearSubcategory('Coat');

    final List<Garment> filtered = container.read(filteredGarmentsProvider);

    expect(filtered.map((Garment garment) => garment.id), <String>['match']);
  });
}
