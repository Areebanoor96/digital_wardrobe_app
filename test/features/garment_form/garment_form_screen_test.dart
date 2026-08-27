import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/garment_form/screens/garment_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Finder> pumpForm(WidgetTester tester, {Garment? garment}) async {
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
}
