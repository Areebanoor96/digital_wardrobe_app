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
              onTap: () => _confirmDeactivateAccount(context),
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

  Future<void> _confirmDeactivateAccount(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Deactivate my account?'),
        content: const Text(
          'This is a high-impact action. Deactivating your account may affect '
          'your profiles, wardrobe and access to the app.\n\n'
          'No data is deleted from this screen.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
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

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Account deactivation'),
        content: const Text(
          'Account deactivation currently requires backend account-management '
          'support that is not available yet. Your account remains active.',
        ),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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