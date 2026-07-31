import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/features/profile/widgets/family_member_avatar.dart';
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

        leading: FamilyMemberAvatar(
          name: member.name,
          avatarUrl: member.avatarUrl,
          radius: 24,
        ),

        title: Text(member.name),

        subtitle: Text(member.relationship.label),

        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case "edit":
                onTap?.call();
                break;

              case "delete":
                onDelete?.call();
                break;
            }
            switch (value) {
              case "edit":
                onTap?.call();
                break;

              case "delete":
                onDelete?.call();
                break;
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
