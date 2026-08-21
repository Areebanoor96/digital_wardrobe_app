import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/wardrobe/providers/wardrobe_filter_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Garment garment({
  required String id,
  String? colorName,
  String? colorHex,
}) {
  return Garment(
    id: id,
    name: 'Garment $id',
    memberId: 'member-1',
    category: GarmentCategory.top,
    photoPaths: const <String>['test/photo.jpg'],
    photoUrls: const <String>[],
    colorName: colorName,
    colorHex: colorHex,
  );
}

void main() {
  testWidgets('color filtering still matches palette and legacy colors', (
    WidgetTester tester,
  ) async {
    final List<Garment> garments = <Garment>[
      garment(id: 'palette', colorName: 'Navy', colorHex: '#000080'),
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
      'legacy',
    ]);
  });
}
