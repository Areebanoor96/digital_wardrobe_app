import 'package:digital_wardrobe_app/features/profile/screens/help_faq_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the help/FAQ screen without a guessed URL', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HelpFaqScreen()));

    expect(find.text('Help / FAQ'), findsOneWidget);
    expect(
      find.text('How do I switch the wardrobe I am using?'),
      findsOneWidget,
    );
    expect(
      find.text('Online help center'),
      findsOneWidget,
    );
    expect(find.textContaining('coming soon'), findsOneWidget);
    expect(find.textContaining('https://'), findsNothing);
  });
}