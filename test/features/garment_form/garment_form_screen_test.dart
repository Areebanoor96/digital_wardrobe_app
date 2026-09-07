import 'dart:async';
import 'dart:io';

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

Future<void> _expandAdvancedOptions(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Advanced Options'));
  await tester.tap(find.text('Advanced Options'));
  await tester.pumpAndSettle();
}

Future<void> _openMultiSelectSheet(
  WidgetTester tester,
  String labelText,
) async {
  final Finder block = find.ancestor(
    of: find.text(labelText),
    matching: find.byType(InputDecorator),
  );
  final Finder addChip = find.descendant(
    of: block,
    matching: find.widgetWithText(ActionChip, 'Add'),
  );

  await tester.ensureVisible(addChip);
  await tester.tap(addChip);
  await tester.pumpAndSettle();
}

Future<void> _closeMultiSelectSheet(WidgetTester tester) async {
  await tester.tap(find.text('Done'));
  await tester.pumpAndSettle();
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

      expect(find.text('Shades *'), findsOneWidget);
      expect(find.text('Add'), findsWidgets);

      expect(find.text('Sizes'), findsOneWidget);
      await _openMultiSelectSheet(tester, 'Sizes');
      for (final String size in <String>[
        childSizes.first,
        childSizes.last,
        adultSizes.first,
        adultSizes.last,
      ]) {
        expect(find.text(size), findsOneWidget);
      }
      await _closeMultiSelectSheet(tester);

      expect(find.text('Item Status'), findsOneWidget);
      expect(find.text('Location'), findsWidgets);
      expect(find.text('Stitching Status'), findsNothing);
      expect(find.text('Ironing Status'), findsNothing);
      expect(find.text('Sleeve Length'), findsNothing);

      await _expandAdvancedOptions(tester);

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

    await _expandAdvancedOptions(tester);

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
    expect(find.text('3-4Y'), findsOneWidget);

    await _expandAdvancedOptions(tester);

    expect(find.text('Tailored'), findsOneWidget);
    expect(find.text('Embroidered'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Long Sleeve'), findsOneWidget);
    expect(find.text('Embroidered collar'), findsOneWidget);
  });

  testWidgets('purchase date appears directly above price', (
    WidgetTester tester,
  ) async {
    await pumpForm(tester);

    final double storeTop = tester
        .getTopLeft(find.widgetWithText(TextFormField, 'Store And Location'))
        .dy;
    final double purchaseDateTop = tester
        .getTopLeft(find.widgetWithText(TextFormField, 'Purchase Date'))
        .dy;
    final double priceTop = tester
        .getTopLeft(find.widgetWithText(TextFormField, 'Price (PKR)'))
        .dy;

    expect(purchaseDateTop, greaterThan(storeTop));
    expect(purchaseDateTop, lessThan(priceTop));
    expect(find.text('Occasions'), findsNothing);
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

    await _expandAdvancedOptions(tester);

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

  testWidgets(
    'shoe items use numeric sizes and shoe types, hide clothing fields',
    (WidgetTester tester) async {
      const Garment garment = Garment(
        id: 'g-10',
        name: 'Tennis Sneakers',
        category: GarmentCategory.shoe,
        photoPaths: <String>[],
        photoUrls: <String>[],
        subcategory: 'Sneakers',
        sizes: <String>['40'],
      );

      await pumpForm(tester, garment: garment);

      expect(find.text('Shoe Sizes'), findsOneWidget);
      await _openMultiSelectSheet(tester, 'Shoe Sizes');
      for (final String size in <String>['36', '38', '42']) {
        expect(find.text(size), findsOneWidget);
      }
      expect(find.text('40'), findsWidgets);
      expect(find.text('S'), findsNothing);
      await _closeMultiSelectSheet(tester);

      expect(find.text('Shoe Type'), findsOneWidget);
      expect(find.text('Sneakers'), findsOneWidget);

      expect(find.text('Sizes'), findsNothing);
      expect(find.text('Stitching Status'), findsNothing);
      expect(find.text('Ironing Status'), findsNothing);
      expect(find.text('Fabric'), findsNothing);
      expect(find.text('Fit'), findsNothing);
      expect(find.text('Pattern'), findsNothing);
      expect(find.text('Fabric Weight'), findsNothing);
      expect(find.text('Sleeve Length'), findsNothing);
    },
  );

  testWidgets('bag items show bag types and hide sizes and clothing fields', (
    WidgetTester tester,
  ) async {
    const Garment garment = Garment(
      id: 'g-11',
      name: 'Everyday Tote',
      category: GarmentCategory.bag,
      photoPaths: <String>[],
      photoUrls: <String>[],
      subcategory: 'Tote',
    );

    await pumpForm(tester, garment: garment);

    expect(find.text('Bag Type'), findsOneWidget);
    expect(find.text('Tote'), findsOneWidget);
    expect(find.text('Sizes'), findsNothing);
    expect(find.text('Shoe Sizes'), findsNothing);
    expect(find.text('Stitching Status'), findsNothing);
    expect(find.text('Ironing Status'), findsNothing);
    expect(find.text('Fabric'), findsNothing);
    expect(find.text('Fit'), findsNothing);
    expect(find.text('Pattern'), findsNothing);
    expect(find.text('Fabric Weight'), findsNothing);
    expect(find.text('Sleeve Length'), findsNothing);
  });

  testWidgets('accessory items show type and hide clothing fields', (
    WidgetTester tester,
  ) async {
    const Garment accessory = Garment(
      id: 'g-12',
      name: 'Summer Scarf',
      category: GarmentCategory.accessory,
      photoPaths: <String>[],
      photoUrls: <String>[],
      subcategory: 'Scarf',
    );

    await pumpForm(tester, garment: accessory);

    expect(find.text('Accessory Type'), findsOneWidget);
    expect(find.text('Scarf'), findsOneWidget);
    expect(find.text('Sizes'), findsNothing);
    expect(find.text('Stitching Status'), findsNothing);
    expect(find.text('Ironing Status'), findsNothing);
    expect(find.text('Fabric'), findsNothing);
    expect(find.text('Fit'), findsNothing);
    expect(find.text('Pattern'), findsNothing);
    expect(find.text('Fabric Weight'), findsNothing);
  });

  testWidgets('jewelry items show type and hide clothing fields', (
    WidgetTester tester,
  ) async {
    const Garment jewelry = Garment(
      id: 'g-13',
      name: 'Gold Chain',
      category: GarmentCategory.jewelry,
      photoPaths: <String>[],
      photoUrls: <String>[],
      subcategory: 'Necklace',
    );

    await pumpForm(tester, garment: jewelry);

    expect(find.text('Jewelry Type'), findsOneWidget);
    expect(find.text('Necklace'), findsOneWidget);
    expect(find.text('Sizes'), findsNothing);
    expect(find.text('Stitching Status'), findsNothing);
    expect(find.text('Ironing Status'), findsNothing);
    expect(find.text('Fabric'), findsNothing);
    expect(find.text('Pattern'), findsNothing);
    expect(find.text('Fabric Weight'), findsNothing);
  });

  testWidgets('activewear items use activewear types and not outerwear types', (
    WidgetTester tester,
  ) async {
    const Garment activewear = Garment(
      id: 'g-14',
      name: 'Training Tee',
      category: GarmentCategory.activewear,
      photoPaths: <String>[],
      photoUrls: <String>[],
    );

    await pumpForm(tester, garment: activewear);

    expect(find.text('Activewear Type'), findsOneWidget);

    final Finder subcategoryDropdown = find.ancestor(
      of: find.text('Activewear Type'),
      matching: find.byType(DropdownButtonFormField<String?>),
    );
    expect(subcategoryDropdown, findsOneWidget);
    await tester.tap(subcategoryDropdown);
    await tester.pumpAndSettle();

    expect(find.text('Tracksuit'), findsOneWidget);
    expect(find.text('Sports Top'), findsOneWidget);
    expect(find.text('Blazer'), findsNothing);
    expect(find.text('Coat'), findsNothing);
  });

  testWidgets(
    'sleepwear items use sleep/loungewear types and not outerwear types',
    (WidgetTester tester) async {
      const Garment sleepwear = Garment(
        id: 'g-15',
        name: 'Night Tee',
        category: GarmentCategory.sleepwear,
        photoPaths: <String>[],
        photoUrls: <String>[],
      );

      await pumpForm(tester, garment: sleepwear);

      expect(find.text('Sleep/Loungewear Type'), findsOneWidget);

      final Finder subcategoryDropdown = find.ancestor(
        of: find.text('Sleep/Loungewear Type'),
        matching: find.byType(DropdownButtonFormField<String?>),
      );
      expect(subcategoryDropdown, findsOneWidget);
      await tester.tap(subcategoryDropdown);
      await tester.pumpAndSettle();

      expect(find.text('Pajamas'), findsOneWidget);
      expect(find.text('Nightdress'), findsOneWidget);
      expect(find.text('Robe'), findsOneWidget);
      expect(find.text('Blazer'), findsNothing);
      expect(find.text('Coat'), findsNothing);
    },
  );

  testWidgets('watches items use watch types and not outerwear types', (
    WidgetTester tester,
  ) async {
    const Garment watch = Garment(
      id: 'g-16',
      name: 'Chronograph',
      category: GarmentCategory.watches,
      photoPaths: <String>[],
      photoUrls: <String>[],
    );

    await pumpForm(tester, garment: watch);

    expect(find.text('Watch Type'), findsOneWidget);

    final Finder subcategoryDropdown = find.ancestor(
      of: find.text('Watch Type'),
      matching: find.byType(DropdownButtonFormField<String?>),
    );
    expect(subcategoryDropdown, findsOneWidget);
    await tester.tap(subcategoryDropdown);
    await tester.pumpAndSettle();

    expect(find.text('Analog'), findsOneWidget);
    expect(find.text('Digital'), findsOneWidget);
    expect(find.text('Smart'), findsOneWidget);
    expect(find.text('Blazer'), findsNothing);
    expect(find.text('Coat'), findsNothing);
  });

  testWidgets(
    'Other items use a free-form custom label and not a subcategory list',
    (WidgetTester tester) async {
      const Garment other = Garment(
        id: 'g-17',
        name: 'Misc Piece',
        category: GarmentCategory.other,
        photoPaths: <String>[],
        photoUrls: <String>[],
        subcategory: 'Pins',
      );

      await pumpForm(tester, garment: other);

      expect(find.text('Custom Label'), findsOneWidget);
      expect(find.text('Not specified'), findsNothing);
      expect(find.text('Blazer'), findsNothing);

      final Finder customField = find.widgetWithText(
        TextFormField,
        'Custom Label',
      );
      expect(customField, findsOneWidget);
      expect(find.text('Pins'), findsOneWidget);

      await tester.enterText(customField, 'Collector Pin');
      expect(find.text('Collector Pin'), findsOneWidget);
    },
  );

  testWidgets(
    'switching category to Shoes swaps sizes and hides clothing fields',
    (WidgetTester tester) async {
      await pumpForm(tester);

      expect(find.text('Sizes'), findsOneWidget);
      expect(find.text('Stitching Status'), findsNothing);

      final Finder categoryDropdown = find.byType(
        DropdownButtonFormField<GarmentCategory>,
      );
      await tester.tap(categoryDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Shoes').last);
      await tester.pumpAndSettle();

      expect(find.text('Shoe Sizes'), findsOneWidget);
      await _openMultiSelectSheet(tester, 'Shoe Sizes');
      for (final String size in <String>['36', '42']) {
        expect(find.text(size), findsOneWidget);
      }
      await _closeMultiSelectSheet(tester);

      expect(find.text('Sizes'), findsNothing);
      expect(find.text('Stitching Status'), findsNothing);
      expect(find.text('Ironing Status'), findsNothing);
      expect(find.text('Fabric'), findsNothing);
      expect(find.text('Fit'), findsNothing);
      expect(find.text('Pattern'), findsNothing);
      expect(find.text('Fabric Weight'), findsNothing);
      expect(find.text('Sleeve Length'), findsNothing);
    },
  );

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

  testWidgets('add location shows a clear message for a duplicate name', (
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
    await tester.tap(find.text('+ Add New Location'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Location Name'),
      'bedroom almirah',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(locationRepository.createCalls, 0);
    expect(
      find.text('A location named "bedroom almirah" already exists.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'editing a garment owned by another profile is blocked with a clear message',
    (WidgetTester tester) async {
      const FamilyMember otherMember = FamilyMember(
        id: 'member-2',
        name: 'Mia',
        relationship: RelationshipType.sister,
      );
      const Garment garment = Garment(
        id: 'g-9',
        name: 'Mia Kurta',
        memberId: 'member-2',
        category: GarmentCategory.top,
        photoPaths: <String>[],
        photoUrls: <String>[],
      );

      await pumpForm(
        tester,
        garment: garment,
        overrides: <Override>[
          selectedFamilyMemberProvider.overrideWith((Ref ref) => _member),
          familyMemberProvider.overrideWith(
            (Ref ref, String memberId) async =>
                memberId == 'member-2' ? otherMember : null,
          ),
        ],
      );

      expect(find.textContaining('Mia'), findsWidgets);
      expect(find.textContaining('another profile'), findsNothing);

      final FilledButton saveButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save Item'),
      );
      expect(saveButton.onPressed, isNull);
    },
  );

  testWidgets('item status dropdown lists all existing and new statuses', (
    WidgetTester tester,
  ) async {
    await pumpForm(tester);

    await tester.ensureVisible(find.text('Item Status'));
    await tester.tap(find.text('Item Status'));
    await tester.pumpAndSettle();

    for (final String label in <String>[
      'Lent',
      'Borrowed',
      'In Storage',
      'Donated',
      'Lost',
      'Sent For Laundry',
      'Damaged',
      'Sent To Tailor',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Available'), findsWidgets);
  });

  testWidgets('sizes sheet selection persists the chosen size chip', (
    WidgetTester tester,
  ) async {
    await pumpForm(tester);

    expect(find.text('M'), findsNothing);

    await _openMultiSelectSheet(tester, 'Sizes');
    await tester.tap(find.text('M'));
    await tester.pump();
    await _closeMultiSelectSheet(tester);

    expect(find.text('M'), findsOneWidget);
  });

  testWidgets('receipt attachment offers source options and cancel', (
    WidgetTester tester,
  ) async {
    await pumpForm(tester);

    await tester.dragUntilVisible(
      find.text('Add receipt'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.tap(find.text('Add receipt'));
    await tester.pumpAndSettle();

    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
    expect(find.text('Attach from Files'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Add receipt'), findsOneWidget);
  });

  testWidgets('receipt attachment attaches a file and can be removed', (
    WidgetTester tester,
  ) async {
    final File tempFile = File('${Directory.systemTemp.path}/receipt_test.jpg');
    tempFile.writeAsBytesSync(_tinyJpeg);
    final _ReceiptImageService imageService = _ReceiptImageService(
      XFile(tempFile.path),
    );

    await pumpForm(
      tester,
      overrides: <Override>[
        imageServiceProvider.overrideWith((Ref ref) => imageService),
      ],
    );

    await tester.dragUntilVisible(
      find.text('Add receipt'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.tap(find.text('Add receipt'));
    await tester.pumpAndSettle();
    expect(imageService.fileCalls, 0);

    await tester.tap(find.text('Attach from Files'));
    await tester.pumpAndSettle();

    expect(imageService.fileCalls, 1);

    await tester.dragUntilVisible(
      find.textContaining('receipt_test.jpg'),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    expect(find.textContaining('receipt_test.jpg'), findsOneWidget);
    expect(find.text('Add receipt'), findsNothing);

    await tester.tap(find.byTooltip('Remove receipt'));
    await tester.pumpAndSettle();

    expect(find.text('Add receipt'), findsOneWidget);
  });
}

class _ReceiptImageService extends ImageService {
  _ReceiptImageService(this.file) : super(ImagePicker());

  final XFile file;
  int cameraCalls = 0;
  int galleryCalls = 0;
  int fileCalls = 0;

  @override
  Future<XFile?> takePhoto() async {
    cameraCalls++;
    return null;
  }

  @override
  Future<XFile?> pickImageFile() async {
    fileCalls++;
    return file;
  }

  @override
  Future<List<XFile>> pickMultipleFromGallery({required int limit}) async {
    galleryCalls++;
    return const <XFile>[];
  }
}

const List<int> _tinyJpeg = <int>[
  0xFF,
  0xD8,
  0xFF,
  0xE0,
  0x00,
  0x10,
  0x4A,
  0x46,
  0x49,
  0x46,
  0x00,
  0x01,
  0x01,
  0x00,
  0x00,
  0x01,
  0x00,
  0x01,
  0x00,
  0x00,
  0xFF,
  0xDB,
  0x00,
  0x43,
  0x00,
  0x08,
  0x06,
  0x06,
  0x07,
  0x06,
  0x05,
  0x08,
  0x07,
  0x07,
  0x07,
  0x09,
  0x09,
  0x08,
  0x0A,
  0x0C,
  0x14,
  0x0D,
  0x0C,
  0x0B,
  0x0B,
  0x0C,
  0x19,
  0x12,
  0x13,
  0x0F,
  0x14,
  0x1D,
  0x1A,
  0x1F,
  0x1E,
  0x1D,
  0x1A,
  0x1C,
  0x1C,
  0x20,
  0x24,
  0x2E,
  0x27,
  0x20,
  0x22,
  0x2C,
  0x23,
  0x1C,
  0x1C,
  0x28,
  0x37,
  0x29,
  0x2C,
  0x30,
  0x31,
  0x34,
  0x34,
  0x34,
  0x1F,
  0x27,
  0x39,
  0x3D,
  0x38,
  0x32,
  0x3C,
  0x2E,
  0x33,
  0x34,
  0x32,
  0xFF,
  0xC0,
  0x00,
  0x0B,
  0x08,
  0x00,
  0x01,
  0x00,
  0x01,
  0x01,
  0x01,
  0x11,
  0x00,
  0xFF,
  0xC4,
  0x00,
  0x1F,
  0x00,
  0x00,
  0x01,
  0x05,
  0x01,
  0x01,
  0x01,
  0x01,
  0x01,
  0x01,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x01,
  0x02,
  0x03,
  0x04,
  0x05,
  0x06,
  0x07,
  0x08,
  0x09,
  0x0A,
  0xFF,
  0xC4,
  0x00,
  0xB5,
  0x11,
  0x00,
  0x02,
  0x01,
  0x02,
  0x03,
  0x04,
  0x05,
  0x06,
  0x07,
  0x08,
  0x09,
  0x0A,
  0x0B,
  0x01,
  0x02,
  0x03,
  0x04,
  0x05,
  0x06,
  0x07,
  0x08,
  0x09,
  0x0A,
  0xBB,
  0xFF,
  0xC4,
  0x00,
  0xB7,
  0x11,
  0x00,
  0x02,
  0x01,
  0x02,
  0x03,
  0x04,
  0x05,
  0x06,
  0x07,
  0x08,
  0x09,
  0x0A,
  0x0B,
  0x01,
  0x02,
  0x03,
  0x04,
  0x05,
  0x06,
  0x07,
  0x08,
  0x09,
  0x0A,
  0xBB,
  0xFF,
  0xDA,
  0x00,
  0x0C,
  0x03,
  0x01,
  0x00,
  0x02,
  0x11,
  0x03,
  0x11,
  0x00,
  0x3F,
  0x00,
  0x37,
  0x92,
  0x26,
  0xBC,
  0x43,
  0xFE,
  0x80,
  0x00,
  0x7F,
  0xFF,
  0xD9,
];

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
