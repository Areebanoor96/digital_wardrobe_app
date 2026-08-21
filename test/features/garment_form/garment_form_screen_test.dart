import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/garment_form/screens/garment_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Finder> pumpForm(
  WidgetTester tester, {
  Garment? garment,
}) async {
  // Enlarge the test surface so every form field is built inside the
  // lazy ListView.
  tester.view.physicalSize = const Size(1080, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(home: GarmentFormScreen(garment: garment)),
    ),
  );
  await tester.pump();

  return find.byType(GarmentFormScreen);
}

void main() {
  const List<String> childSizes = <String>[
    '0-1M',
    '0-3M',
    '3-6M',
    '6-9M',
    '9-12M',
    '1-2Y',
    '2-3Y',
    '3-4Y',
    '4-5Y',
    '5-6Y',
    '6-7Y',
    '7-8Y',
    '9-10Y',
    '11-12Y',
    '12-14Y',
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

  testWidgets('add form shows palette fields, sizes, fabric and details', (
    WidgetTester tester,
  ) async {
    await pumpForm(tester);

    expect(find.text('Primary color *'), findsOneWidget);
    expect(find.text('Secondary color (optional)'), findsOneWidget);
    expect(find.text('Select a shade'), findsNWidgets(2));

    final DropdownButton<String> sizeButton =
        tester.widget<DropdownButton<String>>(
          find.byType(DropdownButton<String>),
        );

    final List<String?> sizeValues = sizeButton.items!
        .map((DropdownMenuItem<String> item) => item.value)
        .toList();

    expect(sizeValues.length, childSizes.length + adultSizes.length);
    for (int index = 0; index < childSizes.length; index++) {
      expect(sizeValues[index], childSizes[index]);
    }
    for (int index = 0; index < adultSizes.length; index++) {
      expect(
        sizeValues[childSizes.length + index],
        adultSizes[index],
      );
    }

    final DropdownButton<String?> fabricButton =
        tester.widget<DropdownButton<String?>>(
          find.byType(DropdownButton<String?>),
        );

    final List<String?> fabricValues = fabricButton.items!
        .map((DropdownMenuItem<String?> item) => item.value)
        .toList();

    expect(fabricValues.first, isNull);
    expect(fabricValues, containsAll(<String>['Cotton', 'Khaddar', 'Denim']));

    expect(find.text('0/100'), findsOneWidget);
  });

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
      details: 'Embroidered collar',
    );

    await pumpForm(tester, garment: garment);

    expect(find.text('Navy'), findsOneWidget);
    expect(find.text('Cream'), findsOneWidget);
    expect(find.text('Lawn'), findsOneWidget);
    expect(find.text('Embroidered collar'), findsOneWidget);
    expect(find.text('3-4Y'), findsOneWidget);
  });

  testWidgets('edit form keeps legacy free-text colors and fabrics', (
    WidgetTester tester,
  ) async {
    const Garment garment = Garment(
      id: 'g-2',
      name: 'Old Shirt',
      category: GarmentCategory.top,
      photoPaths: <String>[],
      photoUrls: <String>[],
      colorName: 'Dark Blue',
      fabric: 'Handloom',
    );

    await pumpForm(tester, garment: garment);

    expect(find.text('Dark Blue'), findsOneWidget);
    expect(find.text('Handloom'), findsOneWidget);
  });
}
