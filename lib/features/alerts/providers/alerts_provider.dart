import 'dart:async';

import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/alert.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/data/repositories/alerts_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final FutureProvider<List<Alert>> alertsProvider =
FutureProvider<List<Alert>>((Ref ref) async {
  final FamilyMember? selectedMember = ref.watch(
    selectedFamilyMemberProvider,
  );

  if (selectedMember == null) {
    return const <Alert>[];
  }

  final AlertsRepository repository = ref.watch(
    alertsRepositoryProvider,
  );

  await repository.generateAndInsertAlerts(
    memberId: selectedMember.id,
  );

  ref.keepAlive();

  return repository.fetchAlerts(
    memberId: selectedMember.id,
  );
});

final alertMutationControllerProvider =
AutoDisposeAsyncNotifierProvider<AlertMutationController, void>(
  AlertMutationController.new,
);

class AlertMutationController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> markAsRead(String alertId) async {
    state = const AsyncLoading<void>();

    state = await AsyncValue.guard(
          () => ref.read(alertsRepositoryProvider).markAsRead(alertId),
    );

    if (!state.hasError) {
      ref.invalidate(alertsProvider);
    }
  }

  Future<void> dismissAlert(String alertId) async {
    state = const AsyncLoading<void>();

    state = await AsyncValue.guard(
          () => ref.read(alertsRepositoryProvider).dismissAlert(alertId),
    );

    if (!state.hasError) {
      ref.invalidate(alertsProvider);
    }
  }

  Future<void> regenerateAlerts() async {
    final FamilyMember? selectedMember = ref.read(
      selectedFamilyMemberProvider,
    );

    if (selectedMember == null) {
      state = AsyncError<void>(
        StateError('No profile selected.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading<void>();

    state = await AsyncValue.guard(
          () => ref
          .read(alertsRepositoryProvider)
          .generateAndInsertAlerts(
        memberId: selectedMember.id,
      ),
    );

    if (!state.hasError) {
      ref.invalidate(alertsProvider);
    }
  }
}