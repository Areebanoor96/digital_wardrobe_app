import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/core/providers/theme_provider.dart';
import 'package:digital_wardrobe_app/core/services/profile_session_service.dart';
import 'package:digital_wardrobe_app/core/services/supabase_service.dart';
import 'package:digital_wardrobe_app/core/services/theme_preference_service.dart';
import 'package:digital_wardrobe_app/core/widgets/back_arrow_button.dart';

import 'package:digital_wardrobe_app/data/models/profile.dart';
import 'package:digital_wardrobe_app/features/auth/screens/change_password_screen.dart';
import 'package:digital_wardrobe_app/features/profile/Family/screens/family_screen.dart';
import 'package:digital_wardrobe_app/features/profile/screens/about_screen.dart';
import 'package:digital_wardrobe_app/features/profile/screens/help_faq_screen.dart';
import 'package:digital_wardrobe_app/features/profile/screens/notification_preferences_screen.dart';
import 'package:digital_wardrobe_app/features/profile/widgets/family_member_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({
    super.key,
    this.canNavigateBack = false,
    this.onNavigateBack,
  });

  final bool canNavigateBack;
  final VoidCallback? onNavigateBack;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    final selectedMember = ref.watch(selectedFamilyMemberProvider);
    final String email = SupabaseService.client.auth.currentUser?.email ?? '';
    return Scaffold(
      appBar: AppBar(
        leading: canNavigateBack
            ? BackArrowButton(onPressed: onNavigateBack)
            : null,
        title: const Text('Profile'),
      ),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Could not load profile.')),
        data: (Profile user) => ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            FamilyMemberAvatar(
              name: user.fullName ?? email,
              radius: 40,
            ),
            const SizedBox(height: 16),
            Text(
              user.fullName ?? email,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(email, textAlign: TextAlign.center),
            const SizedBox(height: 28),

            const _SectionHeader('Profile'),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Manage Family Members'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const FamilyScreen(),
                ),
              ),
            ),

            const _SectionHeader('Notifications'),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notifications'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) =>
                      const NotificationPreferencesScreen(),
                ),
              ),
            ),

            const _SectionHeader('Settings'),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Account'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _editName(context, ref, user.fullName ?? ''),
            ),
            ListTile(
              leading: const Icon(Icons.switch_account_outlined),
              title: const Text('Switch Profile'),
              subtitle: Text(
                selectedMember == null
                    ? 'No wardrobe selected'
                    : 'Currently using ${selectedMember.name}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/profiles'),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openChangePassword(context),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark Mode'),
              subtitle: const Text('Switch to a dark color scheme.'),
              value: ref.watch(themeModeProvider) == ThemeMode.dark,
              onChanged: (bool value) => _setDarkMode(context, ref, value),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About Digital Wardrobe'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const AboutScreen(),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help / FAQ'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const HelpFaqScreen(),
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.person_remove_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Deactivate My Account',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () => _confirmDeactivateAccount(context, ref),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_forever_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Delete My Account Permanently',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () => _confirmDeleteAccount(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log Out'),
              onTap: () async {
                await ProfileSessionService.clearSelectedProfile();

                ref.read(selectedFamilyMemberProvider.notifier).state = null;

                await SupabaseService.client.auth.signOut();

                if (context.mounted) {
                  context.go('/auth');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openChangePassword(BuildContext context) {
    final String email = SupabaseService.client.auth.currentUser?.email ?? '';

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to verify your account email.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ChangePasswordScreen(email: email),
      ),
    );
  }

  Future<void> _setDarkMode(
      BuildContext context, WidgetRef ref, bool enabled) async {
    ref.read(themeModeProvider.notifier).state = enabled
        ? ThemeMode.dark
        : ThemeMode.light;
    await ThemePreferenceService.setDarkModeEnabled(enabled);
  }

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) async {
    final TextEditingController controller = TextEditingController(
      text: currentName,
    );
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Edit account name'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await ref.read(profileRepositoryProvider).updateName(name);
    ref.invalidate(profileProvider);
  }

  Future<void> _confirmDeactivateAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Deactivate my account?'),
        content: const Text(
          'Your account will be temporarily deactivated.\n\n'
          'Your wardrobe, photos, outfits, wear history and profile will all '
          'be preserved.\n\n'
          'You will be signed out, and you can reactivate your account again '
          'later.',
        ),
        actions: <Widget>[
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(accountRepositoryProvider).deactivateAccount();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not deactivate your account. Please try again.'),
        ),
      );
      return;
    }

    if (!context.mounted) return;

    await ProfileSessionService.clearSelectedProfile();
    ref.read(selectedFamilyMemberProvider.notifier).state = null;
    ref.invalidate(profileProvider);

    await SupabaseService.client.auth.signOut();

    if (context.mounted) {
      context.go('/auth');
    }
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => _DeleteAccountConfirmationDialog(),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(accountRepositoryProvider).deleteAccount();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete your account. Please try again.'),
        ),
      );
      return;
    }

    if (!context.mounted) return;

    await ProfileSessionService.clearSelectedProfile();
    ref.read(selectedFamilyMemberProvider.notifier).state = null;
    ref.invalidate(profileProvider);

    await SupabaseService.client.auth.signOut();

    if (context.mounted) {
      context.go('/auth');
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Permanent-deletion confirmation. There is deliberately no Cancel button —
/// the dialog can still be left without acting via the standard dialog close
/// behaviour (tapping outside / system back). The destructive action is only
/// enabled after the user types `DELETE`, as required by product decisions.
class _DeleteAccountConfirmationDialog extends StatefulWidget {
  const _DeleteAccountConfirmationDialog();

  static const String requiredText = 'DELETE';

  @override
  State<_DeleteAccountConfirmationDialog> createState() =>
      _DeleteAccountConfirmationDialogState();
}

class _DeleteAccountConfirmationDialogState
    extends State<_DeleteAccountConfirmationDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _matches = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {
      _matches = value.trim().toUpperCase() ==
          _DeleteAccountConfirmationDialog.requiredText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Delete my account permanently?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'This will permanently delete your account and all associated '
              'data, including your wardrobe, photos, outfits, wear history '
              'and profile. This cannot be undone.\n\n'
              'To confirm, type DELETE below.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onChanged,
              decoration: const InputDecoration(
                labelText: 'Type DELETE to confirm',
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colors.error,
          ),
          onPressed: _matches ? () => Navigator.pop(context, true) : null,
          child: const Text('Delete Permanently'),
        ),
      ],
    );
  }
}