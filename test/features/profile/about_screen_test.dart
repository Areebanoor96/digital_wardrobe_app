import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/core/services/app_info_service.dart';
import 'package:digital_wardrobe_app/features/profile/screens/about_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const AppInfo _appInfo = AppInfo(
  appName: 'Digital Wardrobe',
  packageName: 'com.example.digital_wardrobe_app',
  versionName: '1.4.0',
  buildNumber: '27',
);

Future<void> _pumpAbout(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        appInfoProvider.overrideWith((Ref ref) async => _appInfo),
      ],
      child: const MaterialApp(home: AboutScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AppInfo.displayVersion', () {
    test('combines version and build number', () {
      const AppInfo info = AppInfo(
        appName: 'Digital Wardrobe',
        packageName: 'pkg',
        versionName: '1.4.0',
        buildNumber: '27',
      );
      expect(info.displayVersion, '1.4.0 (Build 27)');
    });

    test('falls back to version only when build number is empty', () {
      const AppInfo info = AppInfo(
        appName: 'Digital Wardrobe',
        packageName: 'pkg',
        versionName: '1.4.0',
        buildNumber: '',
      );
      expect(info.displayVersion, '1.4.0');
    });
  });

  testWidgets('About screen shows app name, tagline and version', (
    WidgetTester tester,
  ) async {
    await _pumpAbout(tester);

    expect(find.text('About Digital Wardrobe'), findsOneWidget);
    expect(find.text('Digital Wardrobe'), findsOneWidget);
    expect(
      find.text('Your personal wardrobe, outfit and style assistant.'),
      findsOneWidget,
    );
    expect(find.text('App Version'), findsOneWidget);
    expect(find.text('1.4.0 (Build 27)'), findsOneWidget);
  });
}
