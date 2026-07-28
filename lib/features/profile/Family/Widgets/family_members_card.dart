import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:flutter/material.dart';

class FamilyMemberCard extends StatelessWidget {
  const FamilyMemberCard({
    super.key,
    required this.member,
    this.onTap,
    this.onDelete,
  });

  final FamilyMember member;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,

        leading: CircleAvatar(
          child: Text(member.name.characters.first.toUpperCase()),
        ),

        title: Text(member.name),

        subtitle: Text(member.relationship.name),

        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == "edit") {
              onTap?.call();
            }

            if (value == "delete") {
              onDelete?.call();
            }
          },

          itemBuilder: (context) => [
            const PopupMenuItem(value: "edit", child: Text("Edit")),

            const PopupMenuItem(value: "delete", child: Text("Delete")),
          ],
        ),
      ),
    );
  }
}
