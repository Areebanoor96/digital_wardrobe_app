import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:flutter/material.dart';
import 'package:digital_wardrobe_app/features/profile/Family/screens/family_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:digital_wardrobe_app/features/profile/widgets/profile_avatar_card.dart';

class ProfileSelectionScreen extends ConsumerWidget {
  const ProfileSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final family = ref.watch(familyMembersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Who's using the wardrobe?"),
        centerTitle: true,
      ),

      body: family.when(
        loading: () => const Center(child: CircularProgressIndicator()),

        error: (error, stackTrace) => Center(child: Text(error.toString())),

        data: (members) {
          return GridView.builder(
            padding: const EdgeInsets.all(24),

            itemCount: members.length + 1,

            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: .9,
            ),

            itemBuilder: (context, index) {
              if (index == members.length) {
                return InkWell(
                  borderRadius: BorderRadius.circular(20),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FamilyScreen()),
                    );
                  },

                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [
                        CircleAvatar(
                          radius: 40,
                          child: Icon(Icons.add, size: 36),
                        ),

                        SizedBox(height: 16),

                        Text(
                          "Add Profile",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final FamilyMember member = members[index];

              return ProfileAvatarCard(
                member: member,
                locked: false,
                onTap: () {
                  ref.read(selectedFamilyMemberProvider.notifier).state = member;

                  context.go('/app');
                },
);

