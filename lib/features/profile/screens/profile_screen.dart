import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/core/services/supabase_service.dart';
import 'package:digital_wardrobe_app/data/models/profile.dart';
import 'package:digital_wardrobe_app/features/profile/Family/screens/family_screen.dart';
import 'package:digital_wardrobe_app/core/services/profile_session_service.dart';
import 'package:digital_wardrobe_app/features/profile/widgets/family_member_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    final selectedMember = ref.watch(selectedFamilyMemberProvider);
    final String email = SupabaseService.client.auth.currentUser?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Could not load profile.')),
        data: (Profile user) => ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            FamilyMemberAvatar(
              name: selectedMember?.name ?? user.fullName ?? email,
              avatarUrl: selectedMember?.avatarUrl,
              radius: 40,
            ),
            const SizedBox(height: 16),
            Text(
              selectedMember?.name ?? user.fullName ?? 'Your name',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(email, textAlign: TextAlign.center),
            const SizedBox(height: 28),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Account name'),
              onTap: () => _editName(context, ref, user.fullName ?? ''),
            ),
            ListTile(
              leading: const Icon(Icons.switch_account_outlined),
              title: const Text('Switch profile'),
              subtitle: Text(
                selectedMember == null
                    ? 'No wardrobe selected'
                    : 'Currently using ${selectedMember.name}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/profiles'),
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Manage Family members'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const FamilyScreen(),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log out'),
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
        title: const Text('Edit name'),
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
}
