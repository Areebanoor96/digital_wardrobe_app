import 'dart:async';

import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/alert.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/data/repositories/alerts_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final AsyncNotifierProvider<AlertsController, List<Alert>> alertsProvider =
    AsyncNotifierProvider<AlertsController, List<Alert>>(AlertsController.new);

class AlertsController extends AsyncNotifier<List<Alert>> {
  @override
  FutureOr<List<Alert>> build() async {
    final FamilyMember? selectedMember = ref.watch(selectedFamilyMemberProvider);

    if (selectedMember == null) {
      return const <Alert>[];
    }

    final AlertsRepository repository = ref.watch(alertsRepositoryProvider);
    await repository.generateAndInsertAlerts(memberId: selectedMember.id);

    return repository.fetchAlerts(memberId: selectedMember.id);
  }

  Future<void> markAsRead(String alertId) async {
    final AsyncValue<List<Alert>> previous = state;
    final List<Alert>? current = previous.valueOrNull;

    if (current != null) {
      final DateTime now = DateTime.now().toUtc();
      state = AsyncData<List<Alert>>(
        current
            .map(
              (Alert alert) => alert.id == alertId
                  ? alert.copyWith(isRead: true, readAt: now)
                  : alert,
            )
            .toList(),
      );
    }

    try {
      await ref.read(alertsRepositoryProvider).markAsRead(alertId);
    } catch (_) {
      state = previous;
      rethrow;
    }
  }

  Future<void> dismissAlert(String alertId) async {
    final AsyncValue<List<Alert>> previous = state;
    final List<Alert>? current = previous.valueOrNull;

    if (current != null) {
      state = AsyncData<List<Alert>>(
        current.where((Alert alert) => alert.id != alertId).toList(),
      );
    }

    try {
      await ref.read(alertsRepositoryProvider).dismissAlert(alertId);
    } catch (_) {
      state = previous;
      rethrow;
    }
  }

  Future<void> regenerateAlerts() async {
    final FamilyMember? selectedMember = ref.read(selectedFamilyMemberProvider);

    if (selectedMember == null) {
      state = AsyncError<List<Alert>>(
        StateError('No profile selected.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading<List<Alert>>();
    state = await AsyncValue.guard(() async {
      final AlertsRepository repository = ref.read(alertsRepositoryProvider);
      await repository.generateAndInsertAlerts(memberId: selectedMember.id);
      return repository.fetchAlerts(memberId: selectedMember.id);
    });
  }
}
