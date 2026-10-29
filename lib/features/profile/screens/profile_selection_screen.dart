import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/core/widgets/back_arrow_button.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/features/profile/Family/screens/family_screen.dart';
import 'package:digital_wardrobe_app/features/profile/utils/select_family_member.dart';
import 'package:digital_wardrobe_app/features/profile/widgets/profile_avatar_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileSelectionScreen extends ConsumerStatefulWidget {
  const ProfileSelectionScreen({super.key});

  @override
  ConsumerState<ProfileSelectionScreen> createState() =>
      _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState
    extends ConsumerState<ProfileSelectionScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final familyAsync = ref.watch(familyMembersProvider);
    final activeMember = ref.watch(selectedFamilyMemberProvider);
    final pieceCounts = ref.watch(familyMemberPieceCountsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F2), // Warm Cream
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? const BackArrowButton()
            : null,
      ),
      body: familyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        data: (List<FamilyMember> members) {
          if (members.isEmpty) {
            return const Center(child: Text('No profiles found'));
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Choose your\nwardrobe',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  letterSpacing: -0.5,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 50),

              // Horizontal Carousel with Left/Right Navigation Arrows
              SizedBox(
                height: 240,
                child: Row(
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 32),
                      onPressed: _currentIndex > 0
                          ? () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                          : null,
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: members.length,
                        onPageChanged: (index) {
                          setState(() => _currentIndex = index);
                        },
                        itemBuilder: (context, index) {
                          final FamilyMember member = members[index];
                          final int count =
                              pieceCounts.valueOrNull?[member.id] ?? 0;

                          return Center(
                            child: SizedBox(
                              width: 180,
                              child: ProfileAvatarCard(
                                member: member,
                                pieceCount: count,
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
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 32),
                      onPressed: _currentIndex < members.length - 1
                          ? () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FamilyScreen()),
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Manage Profiles / Add Profile'),
              ),
            ],
          );
        },
      ),
    );
  }
}