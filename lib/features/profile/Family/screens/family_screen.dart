import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/family_members_card.dart';


class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final family = ref.watch(familyMembersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Family Members"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddMemberDialog(context, ref);
        },
        child: const Icon(Icons.add),
      ),
      body: family.when(
        loading: () =>
        const Center(child: CircularProgressIndicator()),

        error: (_, _) =>
        const Center(child: Text("Failed to load family members")),

        data: (members) {
          if (members.isEmpty) {
            return const Center(
              child: Text("No family members yet"),
            );
          }

          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              final FamilyMember member = members[index];

              return FamilyMemberCard(
                member: member,

                onTap: (){
                  _showEditMemberDialog(
                    context,
                    ref,
                    member,
                  );
                },


                onDelete: () async {

                  await ref
                      .read(familyRepositoryProvider)
                      .deleteFamilyMember(member.id);


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
Future<void> _showAddMemberDialog(
    BuildContext context,
    WidgetRef ref,
    ) async {
  final nameController = TextEditingController();

  RelationshipType relationship = RelationshipType.self;
  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Add Family Member"),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Name",
                    ),
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<RelationshipType>(
                    initialValue: relationship,
                    decoration: const InputDecoration(
                      labelText: "Relationship",
                    ),
                    items: RelationshipType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          relationship = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
        actions: [

          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),

          FilledButton(
            onPressed: () async {

              if (nameController.text.trim().isEmpty) {
                return;
              }

              await ref.read(familyRepositoryProvider).addFamilyMember(
                name: nameController.text.trim(),
                relationship: relationship.name,
              );

              ref.invalidate(familyMembersProvider);

              if (context.mounted) {
                Navigator.pop(context);
              }

            },
            child: const Text("Save"),
          ),

        ],
      );
    },
  );

}
Future<void> _showEditMemberDialog(
    BuildContext context,
    WidgetRef ref,
    FamilyMember member,
    ) async {

  final controller =
  TextEditingController(text: member.name);


  await showDialog(
    context: context,
    builder:(context){

      return AlertDialog(

        title: const Text(
          "Edit Family Member",
        ),

        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Name",
          ),
        ),


        actions:[

          TextButton(
            onPressed: (){
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),


          FilledButton(
            onPressed: () async {

              await ref
                  .read(familyRepositoryProvider)
                  .updateFamilyMember(
                id: member.id,
                name: controller.text.trim(),
                relationship:
                member.relationship.name,
              );


              ref.invalidate(
                familyMembersProvider,
              );


              if (context.mounted) {
                Navigator.pop(context);
              }

            },

            child: const Text("Save"),

          )

        ],

      );

    },
  );

}