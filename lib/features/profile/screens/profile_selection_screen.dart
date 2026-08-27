import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/core/widgets/back_arrow_button.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/features/profile/Family/screens/family_screen.dart';
import 'package:digital_wardrobe_app/features/profile/widgets/profile_avatar_card.dart';
import 'package:digital_wardrobe_app/features/profile/utils/select_family_member.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileSelectionScreen extends ConsumerWidget {
  const ProfileSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final family = ref.watch(familyMembersProvider);
    final pieceCounts = ref.watch(familyMemberPieceCountsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Navigator.of(context).canPop() ? const BackArrowButton() : null,
        title: const Text("Choose your wardrobe"),
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
              mainAxisExtent: 200,
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
                          radius: 36,
                          child: Icon(Icons.add, size: 32),
                        ),
                        SizedBox(height: 12),
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
                pieceCount: pieceCounts.valueOrNull?[member.id] ?? 0,
                onTap: () async {
                  final bool selected = await selectFamilyMember(
                    context: context,
                    ref: ref,
                    member: member,
                  );

                  if (!context.mounted || !selected) {
                    return;
                  }

                  context.go('/app');
                },
              );
            },
          );
        },
      ),
    );
  }
}
