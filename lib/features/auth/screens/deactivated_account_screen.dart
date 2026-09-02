import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/core/services/profile_session_service.dart';
import 'package:digital_wardrobe_app/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Shown a signed-in user whose account is temporarily deactivated.
///
/// The session is deliberately kept so the user can reactivate in place — the
/// account status is authoritative and read from the server. Reactivation calls
/// the service-role Edge Function; after success the app resumes normally.
class DeactivatedAccountScreen extends ConsumerStatefulWidget {
  const DeactivatedAccountScreen({super.key});

  @override
  ConsumerState<DeactivatedAccountScreen> createState() =>
      _DeactivatedAccountScreenState();
}

class _DeactivatedAccountScreenState
    extends ConsumerState<DeactivatedAccountScreen> {
  bool _busy = false;
  bool _failed = false;

  Future<void> _reactivate() async {
    if (_busy) {
      return;
    }

    setState(() {
      _busy = true;
      _failed = false;
    });

    try {
      await ref.read(accountRepositoryProvider).reactivateAccount();
      ref.invalidate(profileProvider);

      if (!mounted) {
        return;
      }

      // Re-run the normal post-login routing (restores the selected profile).
      context.go('/splash');
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _busy = false;
        _failed = true;
      });
    }
  }

  Future<void> _signOut() async {
    await ProfileSessionService.clearSelectedProfile();
    ref.read(selectedFamilyMemberProvider.notifier).state = null;
    ref.invalidate(profileProvider);
    await ref.read(authControllerProvider).signOut();
    if (mounted) {
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.pause_circle_outline, size: 72, color: colors.primary),
                const SizedBox(height: 20),
                Text(
                  'Account Deactivated',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your account is temporarily deactivated, so you cannot '
                  'continue using the app right now.\n\n'
                  'Your wardrobe, photos, outfits, wear history and profile '
                  'are all preserved.\n\n'
                  'You can reactivate your account at any time.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                if (_failed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Could not reactivate your account. Please try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.error),
                    ),
                  ),
                FilledButton.icon(
                  onPressed: _busy ? null : _reactivate,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.restart_alt),
                  label: Text(
                    _busy ? 'Reactivating...' : 'Reactivate Account',
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _busy ? null : _signOut,
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
