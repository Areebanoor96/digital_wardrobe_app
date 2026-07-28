import 'dart:async';

import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/alert.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final alertsProvider = FutureProvider<List<Alert>>((Ref ref) async {
  final repo = ref.watch(alertsRepositoryProvider);
  await repo.generateAndInsertAlerts();
  ref.keepAlive();
  return repo.fetchAlerts();
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
    state = await AsyncValue.guard(() async {
      await ref.read(alertsRepositoryProvider).markAsRead(alertId);
      ref.invalidate(alertsProvider);
    });
  }

  Future<void> dismissAlert(String alertId) async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(() async {
      await ref.read(alertsRepositoryProvider).dismissAlert(alertId);
      ref.invalidate(alertsProvider);
    });
  }
}
