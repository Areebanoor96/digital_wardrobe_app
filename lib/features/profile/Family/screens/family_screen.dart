import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
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
                  await ref
                      .read(familyRepositoryProvider)
                      .deleteFamilyMember(member);

                  ref.invalidate(familyMembersProvider);
                },
              );
            },
          );
        },
      ),
    );
  }
}

