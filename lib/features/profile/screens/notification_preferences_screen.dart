import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/core/widgets/back_arrow_button.dart';
import 'package:digital_wardrobe_app/data/models/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notification preference switches.
///
/// All toggles are backed by the existing `profiles` alert-preference columns
/// through [ProfileRepository.updateAlertPreferences] — see the
/// `add_alert_preferences` and `add_growth_alert_preference` migrations.
class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Profile> profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const BackArrowButton(),
        title: const Text('Notifications'),
      ),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Could not load profile.')),
        data: (Profile user) => ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Text(
              'Notification preferences',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose which alerts you receive.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(
                  alpha: 0.6,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              secondary: const Icon(Icons.watch_later_outlined),
              title: const Text('Unused garment alerts'),
              subtitle: const Text(
                'Remind me about clothes I have not worn recently.',
              ),
              value: user.unusedAlertsEnabled,
              onChanged: (bool value) async {
                await _updateAlertPreferences(
                  ref,
                  user,
                  unusedAlertsEnabled: value,
                );
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.local_laundry_service_outlined),
              title: const Text('Laundry alerts'),
              subtitle: const Text(
                'Remind me when garments need washing.',
              ),
              value: user.laundryAlertsEnabled,
              onChanged: (bool value) async {
                await _updateAlertPreferences(
                  ref,
                  user,
                  laundryAlertsEnabled: value,
                );
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.auto_awesome_outlined),
              title: const Text('Outfit of the Day'),
              subtitle: const Text(
                'Receive Outfit of the Day reminders.',
              ),
              value: user.ootdAlertsEnabled,
              onChanged: (bool value) async {
                await _updateAlertPreferences(
                  ref,
                  user,
                  ootdAlertsEnabled: value,
                );
              },
            ),
            ],
        ),
      ),
    );
  }

  Future<void> _updateAlertPreferences(
      WidgetRef ref,
      Profile profile, {
        bool? unusedAlertsEnabled,
        bool? laundryAlertsEnabled,
        bool? ootdAlertsEnabled,
      }) async {
    await ref.read(profileRepositoryProvider).updateAlertPreferences(
      unusedAlertsEnabled:
      unusedAlertsEnabled ?? profile.unusedAlertsEnabled,
      laundryAlertsEnabled:
      laundryAlertsEnabled ?? profile.laundryAlertsEnabled,
      ootdAlertsEnabled:
      ootdAlertsEnabled ?? profile.ootdAlertsEnabled,
    );

    ref.invalidate(profileProvider);
  }
}