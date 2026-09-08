import 'dart:async';

import 'package:digital_wardrobe_app/core/theme/app_spacing.dart';
import 'package:digital_wardrobe_app/core/widgets/app_empty_state.dart';
import 'package:digital_wardrobe_app/core/widgets/app_loading_state.dart';
import 'package:digital_wardrobe_app/core/widgets/back_arrow_button.dart';
import 'package:digital_wardrobe_app/data/models/alert.dart';
import 'package:digital_wardrobe_app/features/alerts/navigation/alert_target_resolver.dart';
import 'package:digital_wardrobe_app/features/alerts/providers/alerts_provider.dart';
import 'package:digital_wardrobe_app/features/alerts/widgets/alert_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({
    super.key,
    this.canNavigateBack = false,
    this.onNavigateBack,
  });

  final bool canNavigateBack;
  final VoidCallback? onNavigateBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Alert>> alerts = ref.watch(alertsProvider);
    final bool isRefreshing = alerts.isLoading;

    return Scaffold(
      appBar: AppBar(
        leading: canNavigateBack
            ? BackArrowButton(onPressed: onNavigateBack)
            : null,
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh alerts',
            onPressed: isRefreshing
                ? null
                : () async {
                    await ref
                        .read(alertsProvider.notifier)
                        .regenerateAlerts();
                  },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: alerts.when(
        loading: () => const AppLoadingState(
          showIcon: false,
          label: 'Loading your alerts',
        ),
        error: (Object error, StackTrace stackTrace) => AppErrorState(
          title: 'Could not load alerts',
          message: 'Check your connection and try again.',
          onAction: () {
            ref.invalidate(alertsProvider);
          },
        ),
        data: (List<Alert> items) {
          final int unreadCount =
              items.where((Alert alert) => !alert.isRead).length;

          final Widget content;
          if (items.isEmpty) {
            content = RefreshIndicator(
              onRefresh: () =>
                  ref.read(alertsProvider.notifier).regenerateAlerts(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.md,
                  AppSpacing.xl,
                  AppSpacing.xxxl,
                ),
                children: <Widget>[
                  _AlertsHeader(unreadCount: 0, totalCount: 0),
                  const SizedBox(height: AppSpacing.hero),
                  const AppEmptyState(
                    icon: Icons.notifications_none_outlined,
                    title: 'All caught up!',
                    message: 'You have no alerts right now.',
                  ),
                ],
              ),
            );
          } else {
            content = RefreshIndicator(
              onRefresh: () =>
                  ref.read(alertsProvider.notifier).regenerateAlerts(),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.md,
                  AppSpacing.xl,
                  AppSpacing.xxxl,
                ),
                itemCount: items.length + 1,
                separatorBuilder: (BuildContext context, int index) =>
                    SizedBox(
                      height: index == 0 ? AppSpacing.lg : AppSpacing.md,
                    ),
                itemBuilder: (BuildContext context, int index) {
                  if (index == 0) {
                    return _AlertsHeader(
                      unreadCount: unreadCount,
                      totalCount: items.length,
                    );
                  }

                  final Alert alert = items[index - 1];
                  return AlertCard(
                    alert: alert,
                    onTap: () {
                      _handleAlertTap(context, ref, alert);
                    },
                    onDismiss: () async {
                      await _dismissAlert(context, ref, alert);
                    },
                  );
                },
              ),
            );
          }

          return content;
        },
      ),
    );
  }

  void _handleAlertTap(BuildContext context, WidgetRef ref, Alert alert) {
    final String? route = routeForAlert(alert);

    if (!alert.isRead) {
      unawaited(
        ref
            .read(alertsProvider.notifier)
            .markAsRead(alert.id)
            .catchError((Object error, StackTrace stackTrace) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not mark alert as read.'),
                  ),
                );
              }
            }),
      );
    }

    if (route == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This alert target is no longer available.')),
      );
      return;
    }

    context.push(route);
  }

  Future<void> _dismissAlert(
    BuildContext context,
    WidgetRef ref,
    Alert alert,
  ) async {
    try {
      await ref.read(alertsProvider.notifier).dismissAlert(alert.id);
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not dismiss alert.')),
      );
    }
  }
}

class _AlertsHeader extends StatelessWidget {
  const _AlertsHeader({required this.unreadCount, required this.totalCount});

  final int unreadCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;

    final String subtitle = totalCount == 0
        ? 'No alerts'
        : unreadCount == 0
        ? 'All alerts read'
        : unreadCount == 1
        ? '1 unread alert'
        : '$unreadCount unread alerts';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text('Alerts', style: textTheme.headlineMedium),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: textTheme.labelMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}