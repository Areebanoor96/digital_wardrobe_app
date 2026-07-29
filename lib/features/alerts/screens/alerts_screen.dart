import 'package:digital_wardrobe_app/data/models/alert.dart';
import 'package:digital_wardrobe_app/features/alerts/providers/alerts_provider.dart';
import 'package:digital_wardrobe_app/features/alerts/widgets/alert_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Alert>> alerts = ref.watch(alertsProvider);
    final AsyncValue<void> mutationState = ref.watch(
      alertMutationControllerProvider,
    );

    final bool isMutating = mutationState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh alerts',
            onPressed: isMutating
                ? null
                : () async {
              await ref
                  .read(alertMutationControllerProvider.notifier)
                  .regenerateAlerts();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: alerts.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (Object error, StackTrace stackTrace) => _AlertFeedback(
          icon: Icons.notifications_off_outlined,
          title: 'Could not load alerts',
          message: 'Check your connection and try again.',
          actionLabel: 'Retry',
          onAction: () {
            ref.invalidate(alertsProvider);
          },
        ),
        data: (List<Alert> items) {
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => ref.refresh(alertsProvider.future),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const <Widget>[
                  SizedBox(height: 140),
                  _AlertFeedback(
                    icon: Icons.notifications_none_outlined,
                    title: 'All caught up!',
                    message: 'You have no alerts right now.',
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(alertsProvider.future),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              itemCount: items.length,
              separatorBuilder: (
                  BuildContext context,
                  int index,
                  ) =>
              const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                final Alert alert = items[index];

                return AlertCard(
                  alert: alert,
                  onTap: isMutating || alert.isRead
                      ? null
                      : () async {
                    await ref
                        .read(
                      alertMutationControllerProvider.notifier,
                    )
                        .markAsRead(alert.id);
                  },
                  onDismiss: isMutating
                      ? null
                      : () async {
                    await ref
                        .read(
                      alertMutationControllerProvider.notifier,
                    )
                        .dismissAlert(alert.id);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AlertFeedback extends StatelessWidget {
  const _AlertFeedback({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}