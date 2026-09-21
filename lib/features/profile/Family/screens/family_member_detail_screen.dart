import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/core/widgets/back_arrow_button.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/features/profile/widgets/family_member_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_wardrobe_app/features/profile/Family/widgets/add_family_member_dialog.dart';
class FamilyMemberDetailRouteScreen extends ConsumerWidget {
  const FamilyMemberDetailRouteScreen({super.key, required this.memberId});

  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<FamilyMember?> member = ref.watch(
      familyMemberProvider(memberId),
    );

    return member.when(
      loading: () => const Scaffold(
        appBar: _FamilyMemberLoadingAppBar(),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const _FamilyMemberUnavailableScreen(),
      data: (FamilyMember? value) {
        if (value == null) {
          return const _FamilyMemberUnavailableScreen();
        }

        return FamilyMemberDetailScreen(member: value);
      },
    );
  }
}

class _FamilyMemberLoadingAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _FamilyMemberLoadingAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(leading: const BackArrowButton(), title: const Text('Family'));
  }
}

class _FamilyMemberUnavailableScreen extends StatelessWidget {
  const _FamilyMemberUnavailableScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackArrowButton(),
        title: const Text('Family'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'This family member is no longer available.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class FamilyMemberDetailScreen extends ConsumerWidget {
  const FamilyMemberDetailScreen({super.key, required this.member});

  final FamilyMember member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<FamilyMember?> updatedMember = ref.watch(
      familyMemberProvider(member.id),
    );

    final FamilyMember currentMember = updatedMember.valueOrNull ?? member;

    return Scaffold(
      appBar: AppBar(
        leading: const BackArrowButton(),
        title: Text(currentMember.name),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (BuildContext context) {
                  return AddFamilyMemberDialog(member: currentMember);
                },
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(familyMemberProvider(member.id));
          ref.invalidate(familyMembersProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            _MemberHeader(member: currentMember),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
class _MemberHeader extends StatelessWidget {
  const _MemberHeader({required this.member});

  final FamilyMember member;

  @override
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: <Widget>[
          FamilyMemberAvatar(
            name: member.name,
            avatarUrl: member.avatarUrl,
            radius: 40,
          ),
          const SizedBox(height: 12),
          Text(
            member.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            member.relationship.label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (member.birthDate != null) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              _ageText(member.birthDate!),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _ageText(DateTime birthDate) {
    final DateTime today = DateTime.now();

    int years = today.year - birthDate.year;

    final bool birthdayHasPassed =
        today.month > birthDate.month ||
        (today.month == birthDate.month && today.day >= birthDate.day);

    if (!birthdayHasPassed) {
      years--;
    }

    return '$years years old';
  }
}
