import 'package:digital_wardrobe_app/core/config/supabase_config.dart';
import 'package:digital_wardrobe_app/features/shell/screens/app_shell_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> pumpShell(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(child: MaterialApp(home: AppShellScreen())),
  );
  await tester.pump();
}

Finder _navLabel(String label) => find.descendant(
  of: find.byType(NavigationBar),
  matching: find.text(label),
);

void _setPlatform(TargetPlatform platform) {
  debugDefaultTargetPlatformOverride = platform;
}

void _resetPlatform() {
  debugDefaultTargetPlatformOverride = null;
}

int _selectedTabIndex(WidgetTester tester) => tester
    .widget<NavigationBar>(find.byType(NavigationBar))
    .selectedIndex;

class _InMemoryAuthStorage implements LocalStorage {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => _values.containsKey('accessToken');

  @override
  Future<String?> accessToken() async => _values['accessToken'];

  @override
  Future<void> persistSession(String persistSessionString) async =>
      _values['accessToken'] = persistSessionString;

  @override
  Future<void> removePersistedSession() async => _values.remove('accessToken');
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Supabase.initialize touches the shared_preferences plugin channel
    // internally, which does not exist in the test environment.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (MethodCall call) async {
            if (call.method == 'getAll') {
              return <String, Object>{};
            }
            return null;
          },
        );

    // ProfileScreen reads Supabase.instance during build, so the shell
    // cannot be pumped in tests without initializing Supabase first.
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
      authOptions: FlutterAuthClientOptions(
        localStorage: _InMemoryAuthStorage(),
      ),
    );
  });

  testWidgets('back press from another tab switches to Wardrobe', (
    WidgetTester tester,
  ) async {
    _setPlatform(TargetPlatform.android);
    await pumpShell(tester);

    await tester.tap(_navLabel('Outfits'));
    await tester.pumpAndSettle();
    expect(_selectedTabIndex(tester), 1);

    final bool handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(handled, isTrue);
    expect(_selectedTabIndex(tester), 0);
    _resetPlatform();
  });

  testWidgets('first back on Wardrobe shows exit confirmation', (
    WidgetTester tester,
  ) async {
    _setPlatform(TargetPlatform.android);
    await pumpShell(tester);

    final bool handled = await tester.binding.handlePopRoute();
    await tester.pump();

    expect(handled, isTrue);
    expect(find.text('Press back again to exit.'), findsOneWidget);
    _resetPlatform();
  });

  testWidgets('second back within the window exits the app', (
    WidgetTester tester,
  ) async {
    _setPlatform(TargetPlatform.android);
    bool systemExitRequested = false;

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'SystemNavigator.pop') {
          systemExitRequested = true;
        }
        return null;
      },
    );

    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await pumpShell(tester);

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(systemExitRequested, isFalse);

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(systemExitRequested, isTrue);
    _resetPlatform();
  });

  testWidgets('on iOS, back on Wardrobe does not prompt or exit', (
    WidgetTester tester,
  ) async {
    _setPlatform(TargetPlatform.iOS);
    bool systemExitRequested = false;

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'SystemNavigator.pop') {
          systemExitRequested = true;
        }
        return null;
      },
    );

    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await pumpShell(tester);

    final bool handled = await tester.binding.handlePopRoute();
    await tester.pump();

    expect(handled, isTrue);
    expect(find.text('Press back again to exit.'), findsNothing);
    expect(systemExitRequested, isFalse);

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(systemExitRequested, isFalse);
    _resetPlatform();
  });

  testWidgets('on iOS, back from another tab still returns to Wardrobe', (
    WidgetTester tester,
  ) async {
    _setPlatform(TargetPlatform.iOS);
    await pumpShell(tester);

    await tester.tap(_navLabel('Profile'));
    await tester.pumpAndSettle();
    expect(_selectedTabIndex(tester), 5);

    final bool handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(handled, isTrue);
    expect(_selectedTabIndex(tester), 0);
    expect(find.text('Press back again to exit.'), findsNothing);
    _resetPlatform();
  });
}
