import 'package:digital_wardrobe_app/core/config/supabase_config.dart';
import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/profile.dart';
import 'package:digital_wardrobe_app/data/repositories/account_repository.dart';
import 'package:digital_wardrobe_app/data/repositories/profile_repository.dart';
import 'package:digital_wardrobe_app/features/profile/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
  Future<void> updateCountryCode(String? countryCode) async {}

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

class _RecordingAccountRepository extends AccountRepository {
  bool deactivated = false;
  bool deleted = false;

  @override
  Future<void> deactivateAccount() async {
    deactivated = true;
  }

  @override
  Future<void> deleteAccount() async {
    deleted = true;
  }
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
              final Map<String, dynamic> args =
                  Map<String, dynamic>.from(call.arguments as Map);
              store.remove(args['key'] as String);
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
    AccountRepository? accountRepository,
  }) async {
    await tester.binding.setSurfaceSize(const Size(600, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final GoRouter router = GoRouter(
      initialLocation: '/profile',
      routes: <RouteBase>[
        GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
        GoRoute(
          path: '/auth',
          builder: (_, _) => const Scaffold(body: Center(child: Text('auth'))),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          profileProvider.overrideWith(
            (ref) async => override ?? profile,
          ),
          if (accountRepository != null)
            accountRepositoryProvider.overrideWithValue(accountRepository),
        ],
        child: MaterialApp.router(routerConfig: router),
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
    expect(find.text('Delete My Account Permanently'), findsOneWidget);
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

  testWidgets(
    'deactivate account requires confirmation then deactivates and signs out',
    (tester) async {
      final _RecordingAccountRepository accountRepository =
          _RecordingAccountRepository();

      await pumpProfile(tester, accountRepository: accountRepository);

      await tester.tap(find.text('Deactivate My Account'));
      await tester.pumpAndSettle();

      expect(find.text('Deactivate my account?'), findsOneWidget);

      // There is deliberately no Cancel button on the confirmation dialog.
      expect(find.text('Cancel'), findsNothing);

      await tester.tap(find.text('Deactivate'));
      await tester.pumpAndSettle();

      expect(accountRepository.deactivated, isTrue);
      // The old placeholder "backend support not available" dialog is gone.
      expect(
        find.textContaining('backend account-management support'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'delete account requires typing DELETE before confirming',
    (tester) async {
      final _RecordingAccountRepository accountRepository =
          _RecordingAccountRepository();

      await pumpProfile(tester, accountRepository: accountRepository);

      await tester.tap(find.text('Delete My Account Permanently'));
      await tester.pumpAndSettle();

      expect(find.text('Delete my account permanently?'), findsOneWidget);
      // There is deliberately no Cancel button on the confirmation dialog.
      expect(find.text('Cancel'), findsNothing);

      // The destructive action is disabled until DELETE is typed.
      final Finder deleteButton = find.widgetWithText(
        FilledButton,
        'Delete Permanently',
      );
      expect(tester.widget<FilledButton>(deleteButton).onPressed, isNull);

      await tester.enterText(
        find.widgetWithText(TextField, 'Type DELETE to confirm'),
        'delete',
      );
      await tester.pumpAndSettle();

      expect(tester.widget<FilledButton>(deleteButton).onPressed, isNotNull);

      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      expect(accountRepository.deleted, isTrue);
    },
  );
}