import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/core/providers/theme_provider.dart';
import 'package:digital_wardrobe_app/core/services/profile_session_service.dart';
import 'package:digital_wardrobe_app/core/services/supabase_service.dart';
import 'package:digital_wardrobe_app/core/services/theme_preference_service.dart';
import 'package:digital_wardrobe_app/core/widgets/back_arrow_button.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/data/models/profile.dart';
import 'package:digital_wardrobe_app/features/analytics/screens/analytics_screen.dart';
import 'package:digital_wardrobe_app/features/auth/screens/change_password_screen.dart';
import 'package:digital_wardrobe_app/features/profile/Family/screens/family_screen.dart';
import 'package:digital_wardrobe_app/features/profile/screens/about_screen.dart';
import 'package:digital_wardrobe_app/features/profile/screens/edit_profile_screen.dart';
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
    final AsyncValue<Profile> profileAsync = ref.watch(profileProvider);
    final FamilyMember? activeMember = ref.watch(
      selectedFamilyMemberProvider,
    );
    final String email = SupabaseService.client.auth.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        leading: canNavigateBack
            ? BackArrowButton(onPressed: onNavigateBack)
            : null,
        title: const Text('Profile'),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Could not load profile.')),
        data: (Profile primaryUser) {
          // Resolve the active context: a selected sub-profile (family member)
          // takes precedence over the primary account holder.
          final String displayName =
              activeMember?.name ?? primaryUser.fullName ?? email;
          final String? displayAvatar =
              activeMember?.avatarUrl ?? primaryUser.avatarUrl;
          final String displaySubTitle = _resolveDisplaySubTitle(
            activeMember,
            primaryUser,
            email,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              // 1. Dynamic Context Header
              _ProfileHeaderCard(
                displayName: displayName,
                displayAvatar: displayAvatar,
                displaySubTitle: displaySubTitle,
                isSubProfile: activeMember != null,
              ),
              const SizedBox(height: 24),

              // 2. Section A: Active Profile Actions (contextual)
              const _SectionHeader(title: 'Active Profile'),
              const SizedBox(height: 8),
              _CardGroup(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('Edit Profile'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        _editActiveProfile(context, ref, activeMember),
                  ),
                  ListTile(
                    leading: const Icon(Icons.switch_account_outlined),
                    title: const Text('Switch Profile'),
                    subtitle: Text('Currently managing $displayName'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/profiles'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Section B: Primary Account & System Settings
              const _SectionHeader(title: 'Account & System'),
              const SizedBox(height: 8),
              _CardGroup(
                children: <Widget>[
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
                  ListTile(
                    leading: const Icon(Icons.insights_outlined),
                    title: const Text('Insights & Analytics'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) =>
                            const AnalyticsScreen(canNavigateBack: true),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: const Text('Notifications & Preferences'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) =>
                            const NotificationPreferencesScreen(),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Password & Security'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openChangePassword(context),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode_outlined),
                    title: const Text('Dark Mode'),
                    value: ref.watch(themeModeProvider) == ThemeMode.dark,
                    onChanged: (bool value) =>
                        _setDarkMode(context, ref, value),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 4. Support & Legal
              const _SectionHeader(title: 'Support & Legal'),
              const SizedBox(height: 8),
              _CardGroup(
                children: <Widget>[
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
                ],
              ),
              const SizedBox(height: 20),

              // 5. Danger Zone (always primary account context)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () async {
                  await ProfileSessionService.clearSelectedProfile();
                  ref.read(selectedFamilyMemberProvider.notifier).state = null;
                  await SupabaseService.client.auth.signOut();
                  if (context.mounted) {
                    context.go('/auth');
                  }
                },
                icon: const Icon(Icons.logout, size: 20),
                label: const Text('Log Out'),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => _confirmDeactivateAccount(context, ref),
                    child: Text(
                      'Deactivate Account',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    '•',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _confirmDeleteAccount(context, ref),
                    child: Text(
                      'Delete Account',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  /// Resolves the header subtitle based on the active context.
  ///
  /// The primary user shows their identity line directly beneath the name:
  /// `@username • pronouns` when both are present, falling back to whichever
  /// is available, then email. A selected sub-profile shows its relationship
  /// badge instead (members carry no username/pronouns on the FamilyMember
  /// model or backend).
  String _resolveDisplaySubTitle(
    FamilyMember? activeMember,
    Profile primaryUser,
    String email,
  ) {
    if (activeMember != null) {
      return 'Family Profile • ${activeMember.relationship.label}';
    }

    final List<String> parts = <String>[
      if (primaryUser.username != null && primaryUser.username!.isNotEmpty)
        '@${primaryUser.username}',
      if (primaryUser.pronouns != null && primaryUser.pronouns!.isNotEmpty)
        primaryUser.pronouns!,
    ];

    if (parts.isNotEmpty) {
      return parts.join(' • ');
    }

    return email;
  }

  /// Opens [EditProfileScreen] for the currently active profile.
  ///
  /// The screen edits any profile in the household. When the active member is
  /// the account holder's own `self` row, [EditProfileScreen.profile] is passed
  /// through so the username field appears and `profiles` stays in step.
  ///
  /// Splash and the setup wizard both auto-select the Self member, so the null
  /// case is rare; it still falls back to resolving the Self member explicitly
  /// rather than opening an editor bound to a non-existent row.
  ///
  /// [EditProfileScreen] refreshes the selected member itself after saving, so
  /// the header does not go stale.
  Future<void> _editActiveProfile(
    BuildContext context,
    WidgetRef ref,
    FamilyMember? activeMember,
  ) async {
    FamilyMember? target = activeMember;

    if (target == null) {
      final List<FamilyMember> members =
          await ref.read(familyMembersProvider.future);
      target = members.where((FamilyMember m) => m.isAccount).firstOrNull;
    }

    if (!context.mounted) return;

    final FamilyMember? resolved = target;
    if (resolved == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No profile selected. Choose a profile first.'),
        ),
      );
      return;
    }

    final Profile? primaryUser = ref.read(profileProvider).valueOrNull;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => EditProfileScreen(
          member: resolved,
          profile: resolved.isAccount ? primaryUser : null,
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
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    ref.read(themeModeProvider.notifier).state = enabled
        ? ThemeMode.dark
        : ThemeMode.light;
    await ThemePreferenceService.setDarkModeEnabled(enabled);
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
      builder: (BuildContext context) => const _DeleteAccountConfirmationDialog(),
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

/// Dynamic profile header that renders the active account context: name,
/// avatar (primary user or family member), and a contextual subtitle.
class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.displayName,
    required this.displayAvatar,
    required this.displaySubTitle,
    this.isSubProfile = false,
  });

  final String displayName;
  final String? displayAvatar;
  final String displaySubTitle;
  final bool isSubProfile;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: <Widget>[
          FamilyMemberAvatar(
            name: displayName,
            avatarUrl: displayAvatar,
            radius: 36,
          ),
          const SizedBox(height: 10),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            displaySubTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isSubProfile ? colors.primary : colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small uppercase-style label separating screen sections.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _CardGroup extends StatelessWidget {
  const _CardGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
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
      _matches =
          value.trim().toUpperCase() ==
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
          style: FilledButton.styleFrom(backgroundColor: colors.error),
          onPressed: _matches ? () => Navigator.pop(context, true) : null,
          child: const Text('Delete Permanently'),
        ),
      ],
    );
  }
}