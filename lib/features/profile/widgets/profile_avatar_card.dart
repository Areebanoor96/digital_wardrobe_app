import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:flutter/material.dart';

class ProfileAvatarCard extends StatelessWidget {
  const ProfileAvatarCard({
    super.key,
    required this.member,
    required this.onTap,
    this.locked = false,
  });

  final FamilyMember member;
  final VoidCallback onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 42,
                child: Text(
                  member.name.characters.first.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Text(
                member.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                member.relationship.label,
                style: TextStyle(color: Colors.grey.shade600),
              ),

              const SizedBox(height: 18),

              Icon(
                locked ? Icons.lock : Icons.lock_open,
                color: locked ? Colors.red : Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
