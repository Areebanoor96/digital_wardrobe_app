import 'dart:async';

import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/core/services/image_service.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/garment_location.dart';
import 'package:digital_wardrobe_app/data/repositories/garment_location_repository.dart';
import 'package:digital_wardrobe_app/features/garment_form/screens/garment_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const FamilyMember _member = FamilyMember(
  id: 'member-1',
  name: 'Ava',
  relationship: RelationshipType.child,
);

Future<Finder> pumpForm(
  WidgetTester tester, {
  Garment? garment,
  List<Override> overrides = const <Override>[],
}) async {
  // Enlarge the test surface so every form field is built inside the
  // lazy ListView.
  tester.view.physicalSize = const Size(1080, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(home: GarmentFormScreen(garment: garment)),
    ),
  );
  await tester.pump();

  return find.byType(GarmentFormScreen);
}

void main() {
  const List<String> childSizes = <String>[
    '0-1M',
    '1-3M',
    '3-6M',
    '6-9M',
    '9-12M',
    '12-18M',
    '18-24M',
    '2-3Y',
    '3-4Y',
    '4-5Y',
    '5-6Y',
    '6-7Y',
    '7-8Y',
    '8-9Y',
    '9-10Y',
    '10-11Y',
    '11-12Y',
    '12-13Y',
    '13-14Y',
  ];

  const List<String> adultSizes = <String>[
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    '3XL',
    'Free Size',
    'One Size',
  ];

  testWidgets(
    'add form shows palette fields, sizes, fabric, metadata and details',
    (WidgetTester tester) async {
      await pumpForm(tester);

      expect(find.text('Garment shades *'), findsOneWidget);
      expect(find.text('Add shade'), findsOneWidget);

      expect(find.text('Sizes'), findsOneWidget);
      for (final String size in <String>[
        childSizes.first,
        childSizes.last,
        adultSizes.first,
        adultSizes.last,
      ]) {
        expect(find.text(size), findsOneWidget);
      }
      expect(find.text('Garment Status'), findsWidgets);
      expect(find.text('Location'), findsWidgets);
      expect(find.text('Stitching Status'), findsOneWidget);
      expect(find.text('Ironing Status'), findsOneWidget);

      final List<String?> fabricValues = tester
          .widgetList<DropdownButton<String?>>(
            find.byType(DropdownButton<String?>),
          )
          .expand(
            (DropdownButton<String?> button) => button.items!.map(
              (DropdownMenuItem<String?> item) => item.value,
            ),
          )
          .toList();

      expect(fabricValues.first, isNull);
      expect(fabricValues, containsAll(<String>['Cotton', 'Khaddar', 'Denim']));
      expect(fabricValues, containsAll(<String>['Tailored', 'Solid', 'Heavy']));
      expect(find.text('Sleeve Length'), findsOneWidget);
      expect(find.text('Rainy'), findsNothing);

      expect(find.text('0/100'), findsOneWidget);
    },
  );

  testWidgets('details field enforces the 100 character limit', (
    WidgetTester tester,
  ) async {
    await pumpForm(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Details'),
      'a' * 150,
    );
    await tester.pump();

    expect(find.text('100/100'), findsOneWidget);
  });

  testWidgets('edit form restores saved colors, fabric and details', (
    WidgetTester tester,
  ) async {
    const Garment garment = Garment(
      id: 'g-1',
      name: 'Summer Kurta',
      category: GarmentCategory.top,
      photoPaths: <String>[],
      photoUrls: <String>[],
      colorName: 'Navy',
      colorHex: '#000080',
      secondaryColorName: 'Cream',
      secondaryColorHex: '#FFFDD0',
      size: '3-4Y',
      fabric: 'Lawn',
      fit: 'Tailored',
      pattern: 'Embroidered',
      fabricWeight: 'Light',
      sleeveLength: 'Long Sleeve',
      details: 'Embroidered collar',
    );

    await pumpForm(tester, garment: garment);

    expect(find.text('Navy (Primary)'), findsOneWidget);
    expect(find.text('Cream'), findsOneWidget);
    expect(find.text('Lawn'), findsOneWidget);
    expect(find.text('Tailored'), findsOneWidget);
    expect(find.text('Embroidered'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Long Sleeve'), findsOneWidget);
    expect(find.text('Embroidered collar'), findsOneWidget);
    expect(find.text('3-4Y'), findsOneWidget);
  });

  testWidgets('purchase date appears directly below price', (
    WidgetTester tester,
  ) async {
    await pumpForm(tester);

    final double priceTop = tester
        .getTopLeft(find.widgetWithText(TextFormField, 'Price (PKR)'))
        .dy;
    final double purchaseDateTop = tester
        .getTopLeft(find.widgetWithText(TextFormField, 'Purchase Date'))
        .dy;
    final double occasionsTop = tester.getTopLeft(find.text('Occasions')).dy;

    expect(purchaseDateTop, greaterThan(priceTop));
    expect(purchaseDateTop, lessThan(occasionsTop));
  });

  testWidgets('edit form keeps legacy palette colors and fabrics', (
    WidgetTester tester,
  ) async {
    const Garment garment = Garment(
      id: 'g-2',
      name: 'Old Shirt',
      category: GarmentCategory.top,
      photoPaths: <String>[],
      photoUrls: <String>[],
      colorName: 'Dark Blue',
      colorHex: '#123456',
      fabric: 'Handloom',
    );

    await pumpForm(tester, garment: garment);

    expect(find.text('Dark Blue (Primary)'), findsOneWidget);
    expect(find.text('Handloom'), findsOneWidget);
  });

  testWidgets('Add Photo chooser shows camera gallery files and cancel', (
    WidgetTester tester,
  ) async {
    await pumpForm(tester);

    await tester.tap(find.text('Add photo'));
    await tester.pumpAndSettle();

    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
    expect(find.text('Attach from Files'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Attach image file'), findsNothing);
  });

  testWidgets('Add Photo choices use the correct service paths', (
    WidgetTester tester,
  ) async {
    final _FakeImageService imageService = _FakeImageService();

    await pumpForm(
      tester,
      overrides: <Override>[
        imageServiceProvider.overrideWith((Ref ref) => imageService),
      ],
    );

    await tester.tap(find.text('Add photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take photo'));
    await tester.pumpAndSettle();

    expect(imageService.cameraCalls, 1);
    expect(imageService.galleryCalls, 0);

    await tester.tap(find.text('Add photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();

    expect(imageService.cameraCalls, 1);
    expect(imageService.galleryCalls, 1);

    await tester.tap(find.text('Add photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Attach from Files'));
    await tester.pumpAndSettle();

    expect(imageService.cameraCalls, 1);
    expect(imageService.galleryCalls, 1);
    expect(imageService.fileCalls, 1);
  });

  testWidgets('Sleeve Length has only one empty option', (
    WidgetTester tester,
  ) async {
    await pumpForm(tester);

    final Finder sleeveDropdown = find.byWidgetPredicate(
      (Widget widget) =>
          widget is DropdownButtonFormField<String?> &&
          widget.decoration.labelText == 'Sleeve Length',
    );

    await tester.ensureVisible(sleeveDropdown);
    await tester.tap(sleeveDropdown);
    await tester.pumpAndSettle();

    expect(find.text('Not Applicable'), findsNothing);
    expect(find.text('Not specified'), findsWidgets);
  });

  testWidgets('location selector is saved-only and can add and auto-select', (
    WidgetTester tester,
  ) async {
    final _FakeLocationRepository locationRepository =
        _FakeLocationRepository();

    await pumpForm(
      tester,
      overrides: <Override>[
        selectedFamilyMemberProvider.overrideWith((Ref ref) => _member),
        garmentLocationRepositoryProvider.overrideWith(
          (Ref ref) => locationRepository,
        ),
      ],
    );

    await tester.tap(find.text('Not Specified').first);
    await tester.pumpAndSettle();

    expect(find.text('Bedroom Almirah'), findsOneWidget);
    expect(find.text('Winter Storage Bag'), findsOneWidget);
    expect(find.text('Blue Suitcase'), findsOneWidget);
    expect(find.text('+ Add New Location'), findsOneWidget);
    expect(find.text('Drawer'), findsNothing);
    expect(find.text('Shelf'), findsNothing);

    await tester.tap(find.text('+ Add New Location'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Location Name'),
      'Hall Closet',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(locationRepository.createdNames, <String>['Hall Closet']);
    expect(find.text('Hall Closet'), findsOneWidget);
  });

  testWidgets('location dialog blocks duplicate saves while creating', (
    WidgetTester tester,
  ) async {
    final _FakeLocationRepository locationRepository =
        _FakeLocationRepository();
    final Completer<void> createGate = Completer<void>();
    locationRepository.createGate = createGate;

    await pumpForm(
      tester,
      overrides: <Override>[
        selectedFamilyMemberProvider.overrideWith((Ref ref) => _member),
        garmentLocationRepositoryProvider.overrideWith(
          (Ref ref) => locationRepository,
        ),
      ],
    );

    await tester.tap(find.text('Not Specified').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('+ Add New Location'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Location Name'),
      'Hall Closet',
    );
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(locationRepository.createCalls, 1);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(find.text('Save'), findsNothing);

    createGate.complete();
    await tester.pumpAndSettle();

    expect(locationRepository.createCalls, 1);
    expect(locationRepository.createdNames, <String>['Hall Closet']);
    expect(find.text('Hall Closet'), findsOneWidget);
  });
}

class _FakeImageService extends ImageService {
  _FakeImageService() : super(ImagePicker());

  int cameraCalls = 0;
  int galleryCalls = 0;
  int fileCalls = 0;

  @override
  Future<XFile?> takePhoto() async {
    cameraCalls++;
    return null;
  }

  @override
  Future<List<XFile>> pickMultipleFromGallery({required int limit}) async {
    galleryCalls++;
    return const <XFile>[];
  }

  @override
  Future<XFile?> pickImageFile() async {
    fileCalls++;
    return null;
  }
}

class _FakeLocationRepository extends GarmentLocationRepository {
  _FakeLocationRepository()
    : super(
        SupabaseClient(
          'https://example.supabase.co',
          'anon-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );

  final List<String> createdNames = <String>[];
  int createCalls = 0;
  Completer<void>? createGate;
  final List<GarmentLocation> locations = <GarmentLocation>[
    const GarmentLocation(
      id: 'location-1',
      userId: 'user-1',
      memberId: 'member-1',
      name: 'Bedroom Almirah',
    ),
    const GarmentLocation(
      id: 'location-2',
      userId: 'user-1',
      memberId: 'member-1',
      name: 'Winter Storage Bag',
    ),
    const GarmentLocation(
      id: 'location-3',
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
    await createGate?.future;
    createdNames.add(name);
    final GarmentLocation location = GarmentLocation(
      id: 'location-${locations.length + 1}',
      userId: 'user-1',
      memberId: memberId,
      name: name,
    );
    locations.add(location);
    return location;
  }
}
