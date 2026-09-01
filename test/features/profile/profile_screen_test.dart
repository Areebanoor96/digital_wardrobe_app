import 'package:digital_wardrobe_app/core/config/supabase_config.dart';
import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/profile.dart';
import 'package:digital_wardrobe_app/data/repositories/profile_repository.dart';
import 'package:digital_wardrobe_app/features/profile/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

class _EditNameProfileRepository implements ProfileRepository {
  _EditNameProfileRepository(this.holder);

  final Map<String, Profile> holder;
  bool updated = false;

  @override
  Future<Profile> fetchProfile() async => throw UnimplementedError();

  @override
  Future<void> updateName(String name) async {
    updated = true;
    holder['profile'] = Profile(id: 'user-1', fullName: name);
  }

  @override
  Future<void> updateLocationCity(String? city) async {}

  @override
  Future<void> updateGrowthAlertsEnabled(bool enabled) async {}

  @override
  Future<void> updateAlertPreferences({
    required bool unusedAlertsEnabled,
    required bool laundryAlertsEnabled,
    required bool ootdAlertsEnabled,
    bool? growthAlertsEnabled,
  }) async {}
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    final Map<String, Object> store = <String, Object>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (MethodCall call) async {
            if (call.method == 'getAll') {
              return Map<String, Object>.from(store);
            }
            if (call.method == 'setBool' ||
                call.method == 'setString' ||
                call.method == 'setDouble' ||
                call.method == 'setInt') {
              final Map<String, dynamic> args =
                  Map<String, dynamic>.from(call.arguments as Map);
              store[args['key'] as String] = args['value'] as Object;
              return true;
            }
            if (call.method == 'remove') {
              store.remove(call.arguments as String);
              return true;
            }
            return null;
          },
        );

    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
      authOptions: FlutterAuthClientOptions(
        localStorage: _InMemoryAuthStorage(),
      ),
    );
  });

  const Profile profile = Profile(id: 'user-1', fullName: 'Test User');

  Future<void> pumpProfile(
    WidgetTester tester, {
    Profile? override,
  }) async {
    await tester.binding.setSurfaceSize(const Size(600, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          profileProvider.overrideWith(
            (ref) async => override ?? profile,
          ),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows profile sections and settings entries', (tester) async {
    await pumpProfile(tester);

    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('Manage Family Members'), findsOneWidget);
    expect(find.text('Notifications'), findsWidgets);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Edit Account'), findsOneWidget);
    expect(find.text('Switch Profile'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Dark Mode'), findsOneWidget);
    expect(find.text('About Digital Wardrobe'), findsOneWidget);
    expect(find.text('Help / FAQ'), findsOneWidget);
    expect(find.text('Deactivate My Account'), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);
  });

  testWidgets('Edit Account opens the existing edit-name dialog', (
    tester,
  ) async {
    await pumpProfile(tester);

    await tester.tap(find.text('Edit Account'));
    await tester.pumpAndSettle();

    expect(find.text('Edit account name'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets(
    'Edit Account save immediately updates the displayed account name',
    (tester) async {
      final Map<String, Profile> holder = <String, Profile>{
        'profile': const Profile(id: 'user-1', fullName: 'Old Name'),
      };
      final _EditNameProfileRepository repository =
          _EditNameProfileRepository(holder);

      await tester.binding.setSurfaceSize(const Size(600, 2200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            profileProvider.overrideWith((ref) async => holder['profile']!),
            profileRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Old Name'), findsOneWidget);

      await tester.tap(find.text('Edit Account'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'New Name');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(repository.updated, isTrue);
      expect(find.text('New Name'), findsOneWidget);
      expect(find.text('Old Name'), findsNothing);
    },
  );

  testWidgets('Dark Mode toggle updates the theme mode state', (tester) async {
    await pumpProfile(tester);

    final Finder darkModeTile = find.widgetWithText(
      SwitchListTile,
      'Dark Mode',
    );

    expect(tester.widget<SwitchListTile>(darkModeTile).value, isFalse);

    await tester.tap(darkModeTile);
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(darkModeTile).value, isTrue);
  });

  testWidgets('deactivate account requires confirmation before reporting', (
    tester,
  ) async {
    await pumpProfile(tester);

    await tester.tap(find.text('Deactivate My Account'));
    await tester.pumpAndSettle();

    expect(find.text('Deactivate my account?'), findsOneWidget);

    await tester.tap(find.text('Deactivate'));
    await tester.pumpAndSettle();

    expect(find.text('Account deactivation'), findsOneWidget);
    expect(
      find.textContaining('requires backend account-management support'),
      findsOneWidget,
    );
  });
}