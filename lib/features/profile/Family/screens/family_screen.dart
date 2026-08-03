import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/core/services/profile_session_service.dart';
import 'package:go_router/go_router.dart';
import 'package:digital_wardrobe_app/features/profile/Family/widgets/add_family_member_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/family_members_card.dart';

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final family = ref.watch(familyMembersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Family Members")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog<void>(
            context: context,
            builder: (_) => const AddFamilyMemberDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: family.when(
        loading: () => const Center(child: CircularProgressIndicator()),

        error: (_, _) =>
            const Center(child: Text("Failed to load family members")),

        data: (members) {
          if (members.isEmpty) {
            return const Center(child: Text("No family members yet"));
          }

          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              final FamilyMember member = members[index];

              return FamilyMemberCard(
                member: member,

                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AddFamilyMemberDialog(
                      member: member,
                    ),
                  );
                },

                onDelete: () async {
                  final bool? confirmed = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                        title: Text('Delete ${member.name}?'),
                        content: const Text(
                          'This will permanently delete this profile, including its '
                              'garments, outfits, wear history and related data. '
                              'This action cannot be undone.',
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmed != true) {
                    return;
                  }
                  final FamilyMember? selectedMember = ref.read(
                    selectedFamilyMemberProvider,
                  );
                  final bool isSelectedProfile = selectedMember?.id == member.id;


                  try {
                    await ref
                        .read(familyRepositoryProvider)
                        .deleteFamilyMember(member);

                    ref.invalidate(familyMembersProvider);

                    if (isSelectedProfile) {
                      ref.read(selectedFamilyMemberProvider.notifier).state = null;
                      await ProfileSessionService.clearSelectedProfile();

                      if (context.mounted) {
                        context.go('/profiles');
                      }

                      return;
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${member.name} was deleted.'),
                        ),
                      );
                    }
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Could not delete profile: $error'),
                        ),
                      );
                    }
                  }
                },

              );
            },
          );
        },
      ),
    );
  }

}

