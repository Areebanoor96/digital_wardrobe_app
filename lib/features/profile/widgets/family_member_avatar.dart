import 'package:flutter/material.dart';

class FamilyMemberAvatar extends StatelessWidget {
  const FamilyMemberAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.radius = 24,
  });

  final String name;
  final String? avatarUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final bool hasAvatar =
        avatarUrl != null && avatarUrl!.trim().isNotEmpty;

    final String fallbackLetter = name.trim().isNotEmpty
        ? name.trim().characters.first.toUpperCase()
        : '?';

    return CircleAvatar(
      radius: radius,
      backgroundImage: hasAvatar
          ? NetworkImage(avatarUrl!)
          : null,
      child: hasAvatar
          ? null
          : Text(fallbackLetter),
    );
  }
}