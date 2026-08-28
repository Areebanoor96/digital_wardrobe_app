import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/garment_card.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/garment_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GarmentImage placeholder uses square frame when requested', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 120,
            child: GarmentImage(imageUrl: null, aspectRatio: 1),
          ),
        ),
      ),
    );

    final Size size = tester.getSize(find.byType(GarmentImage));
    expect(size.width, 120);
    expect(size.height, 120);
  });

  testWidgets('GarmentImage network image uses cover crop by default', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 120,
            child: GarmentImage(
              imageUrl: 'https://example.com/garment.jpg',
              aspectRatio: 1,
            ),
          ),
        ),
      ),
    );

    final Image image = tester.widget<Image>(find.byType(Image));
    expect(image.fit, BoxFit.cover);
  });

  testWidgets(
    'GarmentCard image frame is square and card metadata is concise',
    (WidgetTester tester) async {
      const Garment garment = Garment(
        id: 'g-1',
        name: 'Green Coat',
        category: GarmentCategory.outerwear,
        photoPaths: <String>[],
        photoUrls: <String>[],
        colorName: 'Forest Green',
        sizes: <String>['10-11Y', '11-12Y', '12-13Y'],
        laundryStatus: LaundryStatus.dirty,
        ironingStatus: IroningStatus.needsIroning,
        stitchingStatus: StitchingStatus.stitched,
        locationName: 'Bedroom Almirah',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 220,
              child: GarmentCard(garment: garment, onTap: () {}),
            ),
          ),
        ),
      );

      final Finder imageFrame = find
          .ancestor(
            of: find.byType(GarmentImage),
            matching: find.byType(AspectRatio),
          )
          .first;
      final AspectRatio aspectRatio = tester.widget<AspectRatio>(imageFrame);

      expect(aspectRatio.aspectRatio, 1);
      expect(find.text('Forest Green - 10-13Y'), findsOneWidget);
      expect(find.text('Needs washing'), findsNothing);
      expect(find.text('Needs Ironing'), findsNothing);
      expect(find.text('Stitched'), findsNothing);
      expect(find.text('Bedroom Almirah'), findsNothing);
    },
  );

  testWidgets('GarmentCard fits the wardrobe grid without bottom overflow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const Garment garment = Garment(
      id: 'g-1',
      name: 'Very Long Everyday Winter Coat Name',
      category: GarmentCategory.outerwear,
      photoPaths: <String>[],
      photoUrls: <String>[],
      colorName: 'Forest Green',
      sizes: <String>['10-11Y', '11-12Y', '12-13Y'],
      availabilityStatus: GarmentAvailabilityStatus.lent,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: .58,
            children: <Widget>[
              GarmentCard(garment: garment, onTap: () {}),
              GarmentCard(garment: garment, onTap: () {}),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final Finder imageFrame = find
        .ancestor(
          of: find.byType(GarmentImage).first,
          matching: find.byType(AspectRatio),
        )
        .first;
    final AspectRatio aspectRatio = tester.widget<AspectRatio>(imageFrame);
    expect(aspectRatio.aspectRatio, 1);
  });
}
