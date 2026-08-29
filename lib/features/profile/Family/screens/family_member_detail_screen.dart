import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/core/widgets/back_arrow_button.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/data/models/shoe_size.dart';
import 'package:digital_wardrobe_app/features/profile/Family/widgets/edit_shoe_size_dialog.dart';
import 'package:digital_wardrobe_app/features/profile/widgets/family_member_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        title: Text(member.name),
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
            _ShoeSizeCard(member: currentMember),
          ],
        ),
      ),
    );
  }
}

class _ShoeSizeCard extends ConsumerWidget {
  const _ShoeSizeCard({required this.member});

  final FamilyMember member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String raw = member.shoeSize?.trim() ?? '';
    final ShoeSize? parsed = ShoeSize.tryParse(raw);
    final String display = raw.isEmpty
        ? 'Not recorded'
        : (parsed?.label ?? raw);

    return Card(
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: Icon(
          Icons.directions_walk_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Shoe size'),
        subtitle: Text(
          display,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.edit_outlined),
        onTap: () => _editShoeSize(context, ref),
      ),
    );
  }

  Future<void> _editShoeSize(BuildContext context, WidgetRef ref) async {
    final ShoeSizeEditResult? result = await showDialog<ShoeSizeEditResult>(
      context: context,
      builder: (BuildContext dialogContext) {
        return EditShoeSizeDialog(initial: ShoeSize.tryParse(member.shoeSize));
      },
    );

    if (result == null) {
      return;
    }

    final ShoeSize? size = result.$1;
    final bool remove = result.$2;

    // (null, false) means the dialog was cancelled with no change.
    if (!remove && size == null) {
      return;
    }

    final String? shoeSize = remove ? null : size!.label;

    try {
      await ref
          .read(familyRepositoryProvider)
          .updateMemberShoeSize(id: member.id, shoeSize: shoeSize);

      ref.invalidate(familyMemberProvider(member.id));
      ref.invalidate(familyMembersProvider);

      final FamilyMember? selected = ref.read(selectedFamilyMemberProvider);

      if (selected != null && selected.id == member.id) {
        ref.read(selectedFamilyMemberProvider.notifier).state =
            selected.copyWith(shoeSize: shoeSize);
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save shoe size: $error')),
        );
      }
    }
  }
}

class _MemberHeader extends StatelessWidget {
  const _MemberHeader({required this.member});

  final FamilyMember member;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        FamilyMemberAvatar(
          name: member.name,
          avatarUrl: member.avatarUrl,
          radius: 46,
        ),
        const SizedBox(height: 12),
        Text(member.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          member.relationship.label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (member.birthDate != null) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            _ageText(member.birthDate!),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
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
