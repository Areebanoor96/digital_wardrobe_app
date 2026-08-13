import 'package:digital_wardrobe_app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// The splash screen reads the Supabase session during its post-frame callback,
// so this smoke test can only run against a live backend.
void main() {
  testWidgets(
    'app starts on the splash screen',
    (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: DigitalWardrobeApp()));
      expect(find.text('Digital Wardrobe'), findsOneWidget);
    },
    skip: true,
  );
}
