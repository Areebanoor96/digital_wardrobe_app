import 'package:digital_wardrobe_app/data/models/shoe_size.dart';
import 'package:digital_wardrobe_app/features/profile/Family/widgets/shoe_size_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ShoeSize? lastEmitted;

  Future<void> pumpPicker(WidgetTester tester, {ShoeSize? initial}) async {
    lastEmitted = null;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ShoeSizePicker(
              initial: initial,
              onChanged: (ShoeSize? value) => lastEmitted = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Finder choiceChip(String label) =>
      find.widgetWithText(ChoiceChip, label);

  Future<void> switchSystem(WidgetTester tester, String from, String to) async {
    await tester.tap(find.text(from).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(to).last);
    await tester.pumpAndSettle();
  }

  Future<void> addCustomSize(WidgetTester tester, String size) async {
    await tester.tap(find.widgetWithText(ActionChip, 'Other'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), size);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
  }

  testWidgets('defaults to EU and lists infant through adult values', (
    WidgetTester tester,
  ) async {
    await pumpPicker(tester);

    expect(find.text('EU'), findsOneWidget);
    expect(choiceChip('15'), findsOneWidget);
    expect(choiceChip('50'), findsOneWidget);
  });

  testWidgets('selecting a size emits a ShoeSize', (WidgetTester tester) async {
    await pumpPicker(tester);

    await tester.tap(choiceChip('16'));
    await tester.pump();

    expect(
      lastEmitted,
      const ShoeSize(system: ShoeSizeSystem.eu, value: '16'),
    );
  });

  testWidgets('switching system clears the selection', (
    WidgetTester tester,
  ) async {
    await pumpPicker(tester);

    await switchSystem(tester, 'EU', 'UK');

    expect(choiceChip('0'), findsOneWidget);
    expect(choiceChip('14'), findsOneWidget);
    expect(choiceChip('16'), findsNothing);
    expect(lastEmitted, isNull);
  });

  testWidgets('restores a previously saved value', (
    WidgetTester tester,
  ) async {
    const ShoeSize saved = ShoeSize(
      system: ShoeSizeSystem.usYouth,
      value: '2',
    );

    await pumpPicker(tester, initial: saved);

    expect(find.text('US Youth'), findsOneWidget);
    expect(
      tester.widget<ChoiceChip>(choiceChip('2')).selected,
      isTrue,
    );
  });

  testWidgets('keeps a saved custom value that is not in the catalog', (
    WidgetTester tester,
  ) async {
    const ShoeSize saved = ShoeSize(
      system: ShoeSizeSystem.eu,
      value: '48.5',
    );

    await pumpPicker(tester, initial: saved);

    expect(choiceChip('48.5'), findsOneWidget);
    expect(
      tester.widget<ChoiceChip>(choiceChip('48.5')).selected,
      isTrue,
    );
  });

  testWidgets('Other flow adds and selects a custom size', (
    WidgetTester tester,
  ) async {
    await pumpPicker(tester);

    await addCustomSize(tester, '42.5');

    expect(find.text('Add Shoe Size'), findsNothing);
    expect(choiceChip('42.5'), findsOneWidget);
    expect(
      tester.widget<ChoiceChip>(choiceChip('42.5')).selected,
      isTrue,
    );
    expect(
      lastEmitted,
      const ShoeSize(system: ShoeSizeSystem.eu, value: '42.5'),
    );
  });

  testWidgets('Other rejects a duplicate size', (WidgetTester tester) async {
    await pumpPicker(tester);

    await tester.tap(find.widgetWithText(ActionChip, 'Other'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '16');
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('This size is already listed'), findsOneWidget);
  });

  testWidgets('custom value survives switching systems', (
    WidgetTester tester,
  ) async {
    await pumpPicker(tester);

    await addCustomSize(tester, '42.5');

    await switchSystem(tester, 'EU', 'UK');
    expect(choiceChip('42.5'), findsNothing);

    await switchSystem(tester, 'UK', 'EU');
    expect(choiceChip('42.5'), findsOneWidget);
  });
}