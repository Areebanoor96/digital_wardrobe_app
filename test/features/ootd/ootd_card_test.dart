import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/ootd/services/outfit_recommendation_service.dart';
import 'package:digital_wardrobe_app/features/ootd/widgets/ootd_card.dart';
import 'package:digital_wardrobe_app/features/outfits/models/outfit_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Garment garment({
    required String id,
    required String name,
    required GarmentCategory category,
  }) {
    return Garment(
      id: id,
      name: name,
      category: category,
      photoPaths: const <String>[],
      photoUrls: const <String>[],
      memberId: 'member-1',
    );
  }

  final List<Garment> bestItems = <Garment>[
    garment(id: 'shirt', name: 'White Shirt', category: GarmentCategory.top),
    garment(id: 'pants', name: 'Black Pants', category: GarmentCategory.bottom),
    garment(
      id: 'sneakers',
      name: 'White Sneakers',
      category: GarmentCategory.shoe,
    ),
  ];

  final List<Garment> alternativeItems = <Garment>[
    garment(id: 'shirt', name: 'White Shirt', category: GarmentCategory.top),
    garment(
      id: 'chinos',
      name: 'Beige Chinos',
      category: GarmentCategory.bottom,
    ),
    garment(
      id: 'sneakers',
      name: 'White Sneakers',
      category: GarmentCategory.shoe,
    ),
  ];

  final List<Garment> differentItems = <Garment>[
    garment(id: 'dress', name: 'Blue Dress', category: GarmentCategory.dress),
    garment(id: 'flats', name: 'Black Flats', category: GarmentCategory.shoe),
  ];

  OutfitRecommendation recommendation() {
    return OutfitRecommendation(
      garments: bestItems,
      reason: 'Best Match: 85% match. Colors harmonize across the look.',
      score: 85,
      heroGarment: bestItems.first,
      label: 'Best Match',
      reasons: <String>[
        'Colors harmonize well together.',
        'Delivers a crisp silhouette.',
      ],
      weatherScore: 88,
      occasionScore: 90,
      colorScore: 92,
      styleScore: 80,
      rotationScore: 84,
      preferenceScore: 70,
      seasonScore: 86,
      noveltyScore: 75,
      alternatives: <OutfitRecommendation>[
        OutfitRecommendation(
          garments: alternativeItems,
          reason: 'Stylish Alternative: 78% match. Softer everyday tone.',
          score: 78,
          label: 'Stylish Alternative',
          reasons: <String>['Softer color pairing fits casual weekends.'],
        ),
        OutfitRecommendation(
          garments: differentItems,
          reason: 'Something Different: 71% match. A one-piece silhouette.',
          score: 71,
          label: 'Something Different',
          reasons: <String>['A single-piece dress is quick to style.'],
        ),
      ],
    );
  }

  OutfitRecommendation refreshedRecommendation() {
    final Garment coat = garment(
      id: 'coat',
      name: 'Tan Coat',
      category: GarmentCategory.top,
    );
    return OutfitRecommendation(
      garments: <Garment>[
        coat,
        garment(
          id: 'jeans',
          name: 'Blue Jeans',
          category: GarmentCategory.bottom,
        ),
        garment(
          id: 'boots',
          name: 'Brown Boots',
          category: GarmentCategory.shoe,
        ),
      ],
      reason: 'Best Match: 91% match. Layered and seasonally aligned.',
      score: 91,
      heroGarment: coat,
      label: 'Best Match',
      reasons: <String>['Layers balance warmth and style.'],
      alternatives: <OutfitRecommendation>[
        OutfitRecommendation(
          garments: <Garment>[
            coat,
            garment(
              id: 'skirt',
              name: 'Navy Skirt',
              category: GarmentCategory.bottom,
            ),
            garment(
              id: 'boots',
              name: 'Brown Boots',
              category: GarmentCategory.shoe,
            ),
          ],
          reason: 'Stylish Alternative: 86% match. Tailored silhouette.',
          score: 86,
          label: 'Stylish Alternative',
          reasons: <String>['Clean lines with a structured bottom.'],
        ),
      ],
    );
  }

  FilterChip chipOf(WidgetTester tester, String label) {
    final Finder chipFinder = find.ancestor(
      of: find.text(label),
      matching: find.byType(FilterChip),
    );
    return tester.widget<FilterChip>(chipFinder.first);
  }

  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }

  testWidgets('alternative selection changes the displayed recommendation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        OotdCard(
          recommendation: recommendation(),
          outfitContext: const OutfitContext(),
        ),
      ),
    );

    expect(find.text('Black Pants'), findsOneWidget);
    expect(find.text('Best Match 85%'), findsOneWidget);
    expect(chipOf(tester, 'Best Match 85%').selected, isTrue);

    await tester.tap(find.text('Stylish Alternative 78%'));
    await tester.pumpAndSettle();

    expect(find.text('Beige Chinos'), findsOneWidget);
    expect(find.text('Black Pants'), findsNothing);
    expect(chipOf(tester, 'Stylish Alternative 78%').selected, isTrue);
    expect(chipOf(tester, 'Best Match 85%').selected, isFalse);
  });

  testWidgets('switching back to Best Match restores the original', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        OotdCard(
          recommendation: recommendation(),
          outfitContext: const OutfitContext(),
        ),
      ),
    );

    await tester.tap(find.text('Stylish Alternative 78%'));
    await tester.pumpAndSettle();
    expect(find.text('Black Pants'), findsNothing);

    await tester.tap(find.text('Best Match 85%'));
    await tester.pumpAndSettle();

    expect(find.text('Black Pants'), findsOneWidget);
    expect(chipOf(tester, 'Best Match 85%').selected, isTrue);
  });

  testWidgets('all recommendations remain available after selection', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        OotdCard(
          recommendation: recommendation(),
          outfitContext: const OutfitContext(),
        ),
      ),
    );

    await tester.tap(find.text('Something Different 71%'));
    await tester.pumpAndSettle();

    expect(find.text('Blue Dress'), findsOneWidget);
    expect(find.text('Black Flats'), findsOneWidget);
    expect(find.text('Best Match 85%'), findsOneWidget);
    expect(find.text('Stylish Alternative 78%'), findsOneWidget);
    expect(find.text('Something Different 71%'), findsOneWidget);
    expect(chipOf(tester, 'Something Different 71%').selected, isTrue);
  });

  testWidgets('a new recommendation set resets to its fresh best match', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        OotdCard(
          recommendation: recommendation(),
          outfitContext: const OutfitContext(),
        ),
      ),
    );

    await tester.tap(find.text('Something Different 71%'));
    await tester.pumpAndSettle();
    expect(find.text('Blue Dress'), findsOneWidget);

    await tester.pumpWidget(
      wrap(
        OotdCard(
          recommendation: refreshedRecommendation(),
          outfitContext: const OutfitContext(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tan Coat'), findsOneWidget);
    expect(find.text('Blue Jeans'), findsOneWidget);
    expect(find.text('Blue Dress'), findsNothing);
    expect(chipOf(tester, 'Stylish Alternative 86%').selected, isFalse);
  });

  testWidgets('refresh button triggers onRefresh', (WidgetTester tester) async {
    var refreshed = false;
    await tester.pumpWidget(
      wrap(
        OotdCard(
          recommendation: recommendation(),
          outfitContext: const OutfitContext(),
          onRefresh: () => refreshed = true,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();

    expect(refreshed, isTrue);
  });

  testWidgets('save and wear act on the currently displayed recommendation', (
    WidgetTester tester,
  ) async {
    OutfitRecommendation? saved;
    OutfitRecommendation? worn;

    await tester.pumpWidget(
      wrap(
        OotdCard(
          recommendation: recommendation(),
          outfitContext: const OutfitContext(),
          onSave: (OutfitRecommendation current) => saved = current,
          onWear: (OutfitRecommendation current) => worn = current,
        ),
      ),
    );

    await tester.tap(find.text('Stylish Alternative 78%'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(saved, isNotNull);
    expect(
      saved!.garments.map((Garment garment) => garment.id),
      contains('chinos'),
    );
    expect(
      saved!.garments.map((Garment garment) => garment.id),
      isNot(contains('pants')),
    );

    await tester.tap(find.text('Wear'));
    await tester.pump();
    expect(worn, isNotNull);
    expect(
      worn!.garments.map((Garment garment) => garment.id),
      contains('chinos'),
    );
  });

  testWidgets('card does not overflow on a narrow phone', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrap(
        OotdCard(
          recommendation: recommendation(),
          outfitContext: const OutfitContext(),
          onRefresh: () {},
          onContextChanged: (_) {},
          onSave: (_) {},
          onWear: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byTooltip('New look'), findsOneWidget);
  });
}