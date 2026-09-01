import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/profile.dart';
import 'package:digital_wardrobe_app/data/repositories/profile_repository.dart';
import 'package:digital_wardrobe_app/features/profile/screens/notification_preferences_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProfileRepository implements ProfileRepository {
  final List<Map<String, bool>> updates = <Map<String, bool>>[];

  @override
  Future<Profile> fetchProfile() async => throw UnimplementedError();

  @override
  Future<void> updateName(String name) async {}

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
  }) async {
    updates.add(<String, bool>{
      'unused_alerts_enabled': unusedAlertsEnabled,
      'laundry_alerts_enabled': laundryAlertsEnabled,
      'ootd_alerts_enabled': ootdAlertsEnabled,
      if (growthAlertsEnabled case final bool enabled)
        'growth_alerts_enabled': enabled,
    });
  }
}

void main() {
  testWidgets('shows supported notification preferences from the profile', (
    tester,
  ) async {
    const Profile profile = Profile(
      id: 'user-1',
      fullName: 'Test User',
      unusedAlertsEnabled: true,
      laundryAlertsEnabled: false,
      ootdAlertsEnabled: true,
      growthAlertsEnabled: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          profileProvider.overrideWith((ref) async => profile),
          profileRepositoryProvider.overrideWithValue(
            _FakeProfileRepository(),
          ),
        ],
        child: const MaterialApp(home: NotificationPreferencesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    SwitchListTile tile(String title) =>
        tester.widget<SwitchListTile>(
          find.widgetWithText(SwitchListTile, title),
        );

    expect(find.text('Notification preferences'), findsOneWidget);
    expect(tile('Unused garment alerts').value, isTrue);
    expect(tile('Laundry alerts').value, isFalse);
    expect(tile('Outfit of the Day').value, isTrue);
    expect(find.text('Child growth alerts'), findsNothing);
  });

  testWidgets('toggling persists through updateAlertPreferences', (
    tester,
  ) async {
    const Profile profile = Profile(
      id: 'user-1',
      fullName: 'Test User',
      unusedAlertsEnabled: true,
      laundryAlertsEnabled: false,
      ootdAlertsEnabled: true,
      growthAlertsEnabled: true,
    );
    final _FakeProfileRepository repository = _FakeProfileRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          profileProvider.overrideWith((ref) async => profile),
          profileRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: NotificationPreferencesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(SwitchListTile, 'Laundry alerts'));
    await tester.pumpAndSettle();

    expect(repository.updates, hasLength(1));
    expect(repository.updates.single['unused_alerts_enabled'], isTrue);
    expect(repository.updates.single['laundry_alerts_enabled'], isTrue);
    expect(repository.updates.single['ootd_alerts_enabled'], isTrue);
    expect(repository.updates.single.containsKey('growth_alerts_enabled'), isFalse);
  });
}