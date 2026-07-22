import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

        error: (_, __) =>
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

              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(member.name),
                subtitle: Text(member.relationship.label),
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
        content: const Text("Dialog coming next..."),
      );
    },
  );
}