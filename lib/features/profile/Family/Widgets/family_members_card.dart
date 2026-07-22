import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:flutter/material.dart';

class FamilyMemberCard extends StatelessWidget {
  const FamilyMemberCard({
    super.key,
    required this.member,
    this.onTap,
  });


  final FamilyMember member;
  final VoidCallback? onTap;


  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,

        leading: CircleAvatar(
          child: Text(
            member.name.characters.first.toUpperCase(),
          ),
        ),

        title: Text(member.name),

        subtitle: Text(
          member.relationship.name,
        ),

        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
      ),
    );
  }
}