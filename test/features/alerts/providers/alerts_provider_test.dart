import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/alert.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/data/repositories/alerts_repository.dart';
import 'package:digital_wardrobe_app/features/alerts/providers/alerts_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AlertsController optimistic mutations', () {
    test('optimistically dismisses without regenerating alerts', () async {
      final _FakeAlertsRepository repository = _FakeAlertsRepository(
        alerts: <Alert>[_alert(id: 'alert-1'), _alert(id: 'alert-2')],
      );
      final ProviderContainer container = _container(repository);
      addTearDown(container.dispose);

      await container.read(alertsProvider.future);
      await container.read(alertsProvider.notifier).dismissAlert('alert-1');

      final List<Alert> alerts = container.read(alertsProvider).value!;
      expect(alerts.map((Alert alert) => alert.id), <String>['alert-2']);
      expect(repository.generateCount, 1);
      expect(repository.fetchCount, 1);
      expect(repository.dismissCount, 1);
    });

    test('restores dismissed alert when persistence fails', () async {
      final _FakeAlertsRepository repository = _FakeAlertsRepository(
        alerts: <Alert>[_alert(id: 'alert-1'), _alert(id: 'alert-2')],
        failDismiss: true,
      );
      final ProviderContainer container = _container(repository);
      addTearDown(container.dispose);

      await container.read(alertsProvider.future);

      await expectLater(
        container.read(alertsProvider.notifier).dismissAlert('alert-1'),
        throwsStateError,
      );

      final List<Alert> alerts = container.read(alertsProvider).value!;
      expect(alerts.map((Alert alert) => alert.id), <String>[
        'alert-1',
        'alert-2',
      ]);
      expect(repository.generateCount, 1);
      expect(repository.fetchCount, 1);
    });

    test('optimistically marks read without regenerating alerts', () async {
      final _FakeAlertsRepository repository = _FakeAlertsRepository(
        alerts: <Alert>[_alert(id: 'alert-1')],
      );
      final ProviderContainer container = _container(repository);
      addTearDown(container.dispose);

      await container.read(alertsProvider.future);
      await container.read(alertsProvider.notifier).markAsRead('alert-1');

      final Alert alert = container.read(alertsProvider).value!.single;
      expect(alert.isRead, isTrue);
      expect(alert.readAt, isNotNull);
      expect(repository.generateCount, 1);
      expect(repository.fetchCount, 1);
      expect(repository.readCount, 1);
    });

    test('restores unread state when mark-read persistence fails', () async {
      final _FakeAlertsRepository repository = _FakeAlertsRepository(
        alerts: <Alert>[_alert(id: 'alert-1')],
        failRead: true,
      );
      final ProviderContainer container = _container(repository);
      addTearDown(container.dispose);

      await container.read(alertsProvider.future);

      await expectLater(
        container.read(alertsProvider.notifier).markAsRead('alert-1'),
        throwsStateError,
      );

      final Alert alert = container.read(alertsProvider).value!.single;
      expect(alert.isRead, isFalse);
      expect(alert.readAt, isNull);
      expect(repository.generateCount, 1);
      expect(repository.fetchCount, 1);
    });
  });
}

ProviderContainer _container(_FakeAlertsRepository repository) {
  return ProviderContainer(
    overrides: <Override>[
      selectedFamilyMemberProvider.overrideWith((Ref ref) => _member),
      alertsRepositoryProvider.overrideWith((Ref ref) => repository),
    ],
  );
}

final FamilyMember _member = FamilyMember(
  id: 'member-1',
  name: 'Member',
  relationship: RelationshipType.self,
);

Alert _alert({required String id}) {
  return Alert(
    id: id,
    memberId: _member.id,
    userId: 'user-1',
    type: AlertType.unused,
    garmentId: 'garment-1',
    title: 'Alert',
  );
}

class _FakeAlertsRepository extends AlertsRepository {
  _FakeAlertsRepository({
    required List<Alert> alerts,
    this.failDismiss = false,
    this.failRead = false,
  }) : _alerts = List<Alert>.from(alerts),
       super(SupabaseClient('https://example.supabase.co', 'anon-key'));

  final bool failDismiss;
  final bool failRead;
  final List<Alert> _alerts;
  int generateCount = 0;
  int fetchCount = 0;
  int dismissCount = 0;
  int readCount = 0;

  @override
  Future<int> generateAndInsertAlerts({required String memberId}) async {
    generateCount++;
    return 0;
  }

  @override
  Future<List<Alert>> fetchAlerts({required String memberId}) async {
    fetchCount++;
    return List<Alert>.from(_alerts);
  }

  @override
  Future<void> dismissAlert(String alertId) async {
    dismissCount++;
    if (failDismiss) {
      throw StateError('dismiss failed');
    }
  }

  @override
  Future<void> markAsRead(String alertId) async {
    readCount++;
    if (failRead) {
      throw StateError('read failed');
    }
  }
}
