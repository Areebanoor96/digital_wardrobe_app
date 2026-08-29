import 'dart:async';

import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/wear_log.dart';
import 'package:digital_wardrobe_app/features/wardrobe/screens/garment_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const FamilyMember _member = FamilyMember(
  id: 'member-1',
  name: 'Ava',
  relationship: RelationshipType.child,
);

Future<void> _pumpDetail(
  WidgetTester tester,
  Garment garment, {
  List<Override> overrides = const <Override>[],
}) async {
  tester.view.physicalSize = const Size(1080, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        selectedFamilyMemberProvider.overrideWith((Ref ref) => _member),
        garmentProvider.overrideWith((Ref ref, String id) async => garment),
        garmentWearHistoryProvider.overrideWith(
          (Ref ref, String id) async => const <WearLog>[],
        ),
        activeLendingRecordProvider.overrideWith(
          (Ref ref, String id) async => null,
        ),
        ...overrides,
      ],
      child: const MaterialApp(home: GarmentDetailScreen(garmentId: 'g-1')),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('detail screen uses compact metadata tags', (
    WidgetTester tester,
  ) async {
    const Garment garment = Garment(
      id: 'g-1',
      name: 'Forest Coat',
      memberId: 'member-1',
      category: GarmentCategory.outerwear,
      subcategory: 'Coat',
      photoPaths: <String>[],
      photoUrls: <String>[],
      colorShades: <GarmentColorShade>[
        GarmentColorShade(
          name: 'Forest Green',
          hex: '#228B22',
          isPrimary: true,
        ),
        GarmentColorShade(name: 'White', hex: '#FFFFFF'),
      ],
      sizes: <String>['10-11Y', '11-12Y', '12-13Y'],
      seasons: <String>['spring', 'summer', 'autumn'],
      occasions: <String>['work', 'wedding'],
      fabric: 'Wool',
      fit: 'Structured',
      pattern: 'Solid',
      fabricWeight: 'Heavy',
      sleeveLength: 'Long Sleeve',
      stitchingStatus: StitchingStatus.stitched,
      ironingStatus: IroningStatus.ironed,
      locationName: 'Bedroom Almirah',
      laundryStatus: LaundryStatus.clean,
      washInstructions: 'Hand wash',
    );

    await _pumpDetail(tester, garment);

    expect(
      find.byKey(const ValueKey<String>('garment-detail-category-tag')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('garment-detail-availability-tag')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('garment-detail-size-tag')),
      findsOneWidget,
    );
    expect(find.text('10-13Y'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('garment-detail-color-tag')),
      findsOneWidget,
    );
    expect(find.text('Forest Green'), findsOneWidget);
    expect(find.text('White'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('garment-detail-season-tag')),
      findsOneWidget,
    );
    expect(find.text('Spring · Summer · Autumn'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('garment-detail-laundry-tag')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('garment-detail-ironing-tag')),
      findsOneWidget,
    );
    expect(find.text('Item Status'), findsOneWidget);
    expect(find.text('Availability'), findsOneWidget);
    expect(find.text('Care & Readiness'), findsOneWidget);
    expect(find.text('Wash Instructions'), findsOneWidget);
    expect(find.text('Hand wash'), findsOneWidget);
    expect(find.text('Laundry Status'), findsNothing);
    expect(find.text('Ironing'), findsNothing);
    expect(find.text('Clean'), findsOneWidget);
    expect(find.text('Ironed'), findsOneWidget);
    expect(find.text('Item Details'), findsOneWidget);
    expect(find.text('Stitching'), findsOneWidget);
    expect(find.text('Stitched'), findsOneWidget);
    expect(find.text('Fabric'), findsOneWidget);
    expect(find.text('Wool'), findsOneWidget);
  });

  testWidgets('detail screen formats All as All Seasons', (
    WidgetTester tester,
  ) async {
    const Garment garment = Garment(
      id: 'g-1',
      name: 'Everyday Shirt',
      memberId: 'member-1',
      category: GarmentCategory.top,
      photoPaths: <String>[],
      photoUrls: <String>[],
      seasons: <String>['all'],
    );

    await _pumpDetail(tester, garment);

    expect(
      find.byKey(const ValueKey<String>('garment-detail-season-tag')),
      findsOneWidget,
    );
    expect(find.text('All Seasons'), findsOneWidget);
  });

  testWidgets('bag detail omits size tag and uses type label', (
    WidgetTester tester,
  ) async {
    const Garment garment = Garment(
      id: 'g-1',
      name: 'Everyday Tote',
      memberId: 'member-1',
      category: GarmentCategory.bag,
      subcategory: 'Tote',
      photoPaths: <String>[],
      photoUrls: <String>[],
      sizes: <String>['One Size'],
    );

    await _pumpDetail(tester, garment);

    expect(
      find.byKey(const ValueKey<String>('garment-detail-size-tag')),
      findsNothing,
    );
    expect(find.text('Item Details'), findsOneWidget);
    expect(find.text('Bag Type'), findsOneWidget);
    expect(find.text('Tote'), findsWidgets);
    expect(find.text('Fabric'), findsNothing);
    expect(find.text('Fit'), findsNothing);
    expect(find.text('Stitching'), findsNothing);
    expect(find.text('Wash Instructions'), findsNothing);
  });

  testWidgets('mark as worn dialog defaults laundry action to No Change', (
    WidgetTester tester,
  ) async {
    const Garment garment = Garment(
      id: 'g-1',
      name: 'Everyday Shirt',
      memberId: 'member-1',
      category: GarmentCategory.top,
      photoPaths: <String>[],
      photoUrls: <String>[],
    );

    await _pumpDetail(tester, garment);
    await tester.tap(find.text('Mark As Worn'));
    await tester.pumpAndSettle();

    final DropdownButtonFormField<String?> eventDropdown = tester
        .widget<DropdownButtonFormField<String?>>(
          find.byType(DropdownButtonFormField<String?>),
        );
    final InputDecorator notesDecorator = tester.widget<InputDecorator>(
      find.descendant(
        of: find.widgetWithText(TextFormField, 'Notes'),
        matching: find.byType(InputDecorator),
      ),
    );
    final DropdownButtonFormField<LaundryStatus?> laundryDropdown = tester
        .widget<DropdownButtonFormField<LaundryStatus?>>(
          find.byType(DropdownButtonFormField<LaundryStatus?>),
        );

    expect(eventDropdown.decoration.prefixIcon, isNull);
    expect(notesDecorator.decoration.prefixIcon, isNull);
    expect(laundryDropdown.initialValue, isNull);
    expect(find.text('No Change'), findsOneWidget);

    await tester.tap(find.text('No Event'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other').last);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Custom Event'), findsOneWidget);
  });

  testWidgets('successful archive shows success, not failure', (
    WidgetTester tester,
  ) async {
    const Garment garment = Garment(
      id: 'g-1',
      name: 'Everyday Shirt',
      memberId: 'member-1',
      category: GarmentCategory.top,
      photoPaths: <String>[],
      photoUrls: <String>[],
    );

    await _pumpDetail(
      tester,
      garment,
      overrides: <Override>[
        garmentArchiveControllerProvider.overrideWith(
          _SuccessfulArchiveController.new,
        ),
      ],
    );

    await tester.tap(find.byIcon(Icons.archive_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move To Closet Vault'));
    await tester.pumpAndSettle();

    expect(find.text('Moved To Closet Vault.'), findsOneWidget);
    expect(find.text('Could Not Move To Closet Vault.'), findsNothing);
  });

  testWidgets('archive action shows loading and ignores duplicate taps', (
    WidgetTester tester,
  ) async {
    final Completer<void> archiveCompleter = Completer<void>();
    final _SlowArchiveController controller = _SlowArchiveController(
      archiveCompleter,
    );
    const Garment garment = Garment(
      id: 'g-1',
      name: 'Everyday Shirt',
      memberId: 'member-1',
      category: GarmentCategory.top,
      photoPaths: <String>[],
      photoUrls: <String>[],
    );

    await _pumpDetail(
      tester,
      garment,
      overrides: <Override>[
        garmentArchiveControllerProvider.overrideWith(() => controller),
      ],
    );

    await tester.tap(find.byIcon(Icons.archive_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move To Closet Vault'));
    await tester.pump();

    expect(controller.archiveCalls, 1);
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    await tester.tap(find.byTooltip('Move To Closet Vault'));
    await tester.pump();

    expect(controller.archiveCalls, 1);

    archiveCompleter.complete();
    await tester.pumpAndSettle();
  });
}

class _SuccessfulArchiveController extends GarmentArchiveController {
  @override
  Future<void> archive({required String garmentId}) async {
    state = const AsyncData<void>(null);
  }

  @override
  Future<void> restore({required String garmentId}) async {
    state = const AsyncData<void>(null);
  }
}

class _SlowArchiveController extends GarmentArchiveController {
  _SlowArchiveController(this.archiveCompleter);

  final Completer<void> archiveCompleter;
  int archiveCalls = 0;

  @override
  Future<void> archive({required String garmentId}) async {
    archiveCalls++;
    state = const AsyncLoading<void>();
    await archiveCompleter.future;
    state = const AsyncData<void>(null);
  }

  @override
  Future<void> restore({required String garmentId}) async {
    state = const AsyncData<void>(null);
  }
}
