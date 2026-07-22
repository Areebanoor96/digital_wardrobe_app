import 'package:digital_wardrobe_app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app starts on the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const DigitalWardrobeApp());
    expect(find.text('Digital Wardrobe'), findsOneWidget);
  });
}
