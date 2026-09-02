import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/profile.dart';
import 'package:digital_wardrobe_app/data/repositories/profile_repository.dart';
import 'package:digital_wardrobe_app/features/auth/screens/setup_wizard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository(this.profile);

  Profile profile;
  String? savedCountryCode;

  @override
  Future<Profile> fetchProfile() async => profile;

  @override
  Future<void> updateName(String name) async {}

  @override
  Future<void> updateLocationCity(String? city) async {}

  @override
  Future<void> updateCountryCode(String? countryCode) async {
    savedCountryCode = countryCode;
    profile = Profile(
      id: profile.id,
      fullName: profile.fullName,
      locationCity: profile.locationCity,
      countryCode: countryCode,
    );
  }

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
  Future<void> pumpWizard(
    WidgetTester tester,
    Profile profile,
    _FakeProfileRepository profileRepository,
  ) async {
    await tester.binding.setSurfaceSize(const Size(500, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final GoRouter router = GoRouter(
      initialLocation: '/setup',
      routes: <RouteBase>[
        GoRoute(path: '/setup', builder: (_, _) => const SetupWizardScreen()),
        GoRoute(path: '/app', builder: (_, _) => const Scaffold()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          profileProvider.overrideWith((ref) async => profile),
          profileRepositoryProvider.overrideWithValue(profileRepository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('country selector opens a searchable alphabetical list', (
    tester,
  ) async {
    final _FakeProfileRepository repository =
        _FakeProfileRepository(const Profile(id: 'user-1'));
    await pumpWizard(tester, const Profile(id: 'user-1'), repository);

    expect(find.text('Country / Location'), findsOneWidget);
    expect(find.text('Pakistan'), findsOneWidget);

    await tester.tap(find.text('Pakistan'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Select Country / Location'), findsOneWidget);
    // Alphabetical list renders; first entries are visible.
    expect(find.text('Argentina'), findsOneWidget);
    expect(find.text('Australia'), findsOneWidget);
    expect(find.text('Pakistan'), findsOneWidget);
  });

  testWidgets('search filters the country list', (tester) async {
    final _FakeProfileRepository repository =
        _FakeProfileRepository(const Profile(id: 'user-1'));
    await pumpWizard(tester, const Profile(id: 'user-1'), repository);

    await tester.tap(find.text('Pakistan'), warnIfMissed: false);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'united');
    await tester.pumpAndSettle();

    expect(find.text('United Arab Emirates'), findsOneWidget);
    expect(find.text('United Kingdom'), findsOneWidget);
    expect(find.text('United States'), findsOneWidget);
    expect(find.text('Argentina'), findsNothing);
  });

  testWidgets('selecting a country updates the field and persists on finish', (
    tester,
  ) async {
    final _FakeProfileRepository repository =
        _FakeProfileRepository(const Profile(id: 'user-1'));
    await pumpWizard(tester, const Profile(id: 'user-1'), repository);

    await tester.tap(find.text('Pakistan'), warnIfMissed: false);
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('United States'),
      find.descendant(
        of: find.byType(DraggableScrollableSheet),
        matching: find.byType(ListView),
      ),
      const Offset(0, -300),
    );
    await tester.tap(find.text('United States'));
    await tester.pumpAndSettle();

    expect(find.text('United States'), findsOneWidget);
    expect(find.text('USD'), findsWidgets);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    expect(repository.savedCountryCode, 'US');
  });

  testWidgets('existing saved country remains selected when returning', (
    tester,
  ) async {
    const Profile profile = Profile(id: 'user-1', countryCode: 'GB');
    final _FakeProfileRepository repository = _FakeProfileRepository(profile);
    await pumpWizard(tester, profile, repository);

    await tester.pumpAndSettle();

    expect(find.text('United Kingdom'), findsOneWidget);
    expect(find.text('GBP'), findsWidgets);
  });

  testWidgets('renders without overflow on a narrow screen', (tester) async {
    final _FakeProfileRepository repository =
        _FakeProfileRepository(const Profile(id: 'user-1'));
    await pumpWizard(tester, const Profile(id: 'user-1'), repository);

    final FlutterError? overflow = tester.takeException() as FlutterError?;
    expect(overflow, isNull);
  });
}