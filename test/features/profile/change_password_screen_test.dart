import 'package:digital_wardrobe_app/core/config/supabase_config.dart';
import 'package:digital_wardrobe_app/features/auth/providers/auth_provider.dart';
import 'package:digital_wardrobe_app/features/auth/screens/change_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeAuthController extends AuthController {
  String? signInEmail;
  String? signInPassword;
  String? updatePasswordValue;
  bool failSignIn = false;

  @override
  Future<void> signInWithEmail(String email, String password) async {
    signInEmail = email;
    signInPassword = password;
    if (failSignIn) {
      throw const AuthException('Invalid login credentials');
    }
  }

  @override
  Future<UserResponse> updatePassword(String newPassword) async {
    updatePasswordValue = newPassword;
    return UserResponse.fromJson(<String, dynamic>{'id': 'user-1'});
  }
}

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

    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
      authOptions: FlutterAuthClientOptions(
        localStorage: _InMemoryAuthStorage(),
      ),
    );
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    required _FakeAuthController controller,
    bool withRouter = false,
  }) async {
    final Widget home = ChangePasswordScreen(email: 'user@example.com');

    if (withRouter) {
      final GoRouter router = GoRouter(
        initialLocation: '/change-password',
        routes: <RouteBase>[
          GoRoute(
            path: '/change-password',
            builder: (_, _) => home,
          ),
          GoRoute(
            path: '/auth',
            builder: (_, _) => const Scaffold(
              body: Center(child: Text('auth page')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            authControllerProvider.overrideWithValue(controller),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
    } else {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            authControllerProvider.overrideWithValue(controller),
          ],
          child: MaterialApp(home: home),
        ),
      );
    }
    await tester.pumpAndSettle();
  }

  Future<void> enterPasswords(
    WidgetTester tester, {
    required String current,
    required String next,
    required String confirm,
  }) async {
    await tester.enterText(find.byType(TextField).at(0), current);
    await tester.enterText(find.byType(TextField).at(1), next);
    await tester.enterText(find.byType(TextField).at(2), confirm);
  }

  testWidgets('shows strong-password guidance', (tester) async {
    await pumpScreen(tester, controller: _FakeAuthController());

    expect(
      find.textContaining(
        'uppercase and lowercase letters, numbers, and a special character',
      ),
      findsOneWidget,
    );
    expect(find.text('Change Password'), findsOneWidget);
  });

  testWidgets('blocks submit when current password is missing', (tester) async {
    final _FakeAuthController controller = _FakeAuthController();
    await pumpScreen(tester, controller: controller);

    await enterPasswords(
      tester,
      current: '',
      next: 'NewPass1!',
      confirm: 'NewPass1!',
    );
    await tester.tap(find.text('Change Password'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your current password.'), findsOneWidget);
    expect(controller.signInPassword, isNull);
    expect(controller.updatePasswordValue, isNull);
  });

  testWidgets('blocks weak new passwords', (tester) async {
    final _FakeAuthController controller = _FakeAuthController();
    await pumpScreen(tester, controller: controller);

    await enterPasswords(
      tester,
      current: 'Current123!',
      next: 'weakpass',
      confirm: 'weakpass',
    );
    await tester.tap(find.text('Change Password'));
    await tester.pumpAndSettle();

    expect(find.textContaining('uppercase letter'), findsOneWidget);
    expect(controller.signInPassword, isNull);
    expect(controller.updatePasswordValue, isNull);
  });

  testWidgets('blocks confirm mismatch', (tester) async {
    final _FakeAuthController controller = _FakeAuthController();
    await pumpScreen(tester, controller: controller);

    await enterPasswords(
      tester,
      current: 'Current123!',
      next: 'NewPass1!',
      confirm: 'Mismatch1!',
    );
    await tester.tap(find.text('Change Password'));
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(controller.signInPassword, isNull);
    expect(controller.updatePasswordValue, isNull);
  });

  testWidgets('rejects an incorrect current password', (tester) async {
    final _FakeAuthController controller = _FakeAuthController()
      ..failSignIn = true;
    await pumpScreen(tester, controller: controller);

    await enterPasswords(
      tester,
      current: 'Wrong!1',
      next: 'NewPass1!',
      confirm: 'NewPass1!',
    );
    await tester.tap(find.text('Change Password'));
    await tester.pumpAndSettle();

    expect(find.text('Current password is incorrect.'), findsOneWidget);
    expect(controller.updatePasswordValue, isNull);
  });

  testWidgets(
    'verifies current password then updates it through the auth controller',
    (tester) async {
      final _FakeAuthController controller = _FakeAuthController();
      await pumpScreen(tester, controller: controller);

      await enterPasswords(
        tester,
        current: 'Current123!',
        next: 'NewPass1!',
        confirm: 'NewPass1!',
      );
      await tester.tap(find.text('Change Password'));
      await tester.pumpAndSettle();

      expect(controller.signInEmail, 'user@example.com');
      expect(controller.signInPassword, 'Current123!');
      expect(controller.updatePasswordValue, 'NewPass1!');

      expect(find.text('Password updated'), findsOneWidget);
    },
  );
}