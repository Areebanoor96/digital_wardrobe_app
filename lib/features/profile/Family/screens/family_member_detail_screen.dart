import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/core/widgets/back_arrow_button.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/data/models/profile.dart';
import 'package:digital_wardrobe_app/features/profile/screens/edit_profile_screen.dart';
import 'package:digital_wardrobe_app/features/profile/utils/select_family_member.dart';
import 'package:digital_wardrobe_app/features/profile/widgets/family_member_avatar.dart';
import 'package:digital_wardrobe_app/features/shell/screens/app_shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final FamilyMember? activeMember = ref.watch(
      selectedFamilyMemberProvider,
    );

    final FamilyMember currentMember = updatedMember.valueOrNull ?? member;
    final Profile? primaryUser = ref.read(profileProvider).valueOrNull;
    final String displayName = _capitalizedName(currentMember.name);
    final bool isActiveProfile = activeMember?.id == currentMember.id;

    return Scaffold(
      appBar: AppBar(
        leading: const BackArrowButton(),
        title: Text(displayName),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => EditProfileScreen(
                    member: currentMember,
                    profile: currentMember.isAccount ? primaryUser : null,
                  ),
                ),
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
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: <Widget>[
            _MemberHeader(
              member: currentMember,
              displayName: displayName,
              isActiveProfile: isActiveProfile,
            ),
            const SizedBox(height: 16),
            _SizingCard(member: currentMember),
            if (currentMember.styleAesthetics.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              _StyleAestheticsCard(member: currentMember),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _MemberActionBar(
        member: currentMember,
        isActiveProfile: isActiveProfile,
        displayName: displayName,
      ),
    );
  }
}

/// Normalises stored names so a lowercase entry such as `ayesha` renders as
/// `Ayesha` without mangling already-capitalised names like `McDonald`.
String _capitalizedName(String rawName) {
  final String trimmed = rawName.trim();

  if (trimmed.isEmpty) {
    return 'Unnamed';
  }

  return trimmed[0].toUpperCase() + trimmed.substring(1);
}

class _MemberActionBar extends ConsumerWidget {
  const _MemberActionBar({
    required this.member,
    required this.isActiveProfile,
    required this.displayName,
  });

  final FamilyMember member;
  final bool isActiveProfile;
  final String displayName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String label = isActiveProfile
        ? 'View Wardrobe'
        : 'Make $displayName Active';

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                if (!isActiveProfile) {
                  final bool selected = await selectFamilyMember(
                    context: context,
                    ref: ref,
                    member: member,
                  );

                  if (!context.mounted || !selected) {
                    return;
                  }
                }

                if (!context.mounted) {
                  return;
                }

                // The shell holds its tab index in local state, so a bare
                // `go('/app')` reveals whatever tab happened to be active.
                // Requesting tab 0 (Wardrobe) first makes the landing screen
                // deterministic. The shell consumes the request immediately
                // and `_selectTab` no-ops when it is already on tab 0, so
                // this is safe to send unconditionally.
                ref.read(shellTabRequestProvider.notifier).state = 0;

                // `go` replaces the entire route stack, so the `/family/:id`
                // detail route and any screen pushed above it are discarded
                // rather than left behind for back-navigation.
                context.go('/app');
              },
              icon: Icon(
                isActiveProfile
                    ? Icons.checkroom_rounded
                    : Icons.swap_horiz_rounded,
              ),
              label: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberHeader extends StatelessWidget {
  const _MemberHeader({
    required this.member,
    required this.displayName,
    required this.isActiveProfile,
  });

  final FamilyMember member;
  final String displayName;
  final bool isActiveProfile;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.28),
                width: 1.5,
              ),
            ),
            child: FamilyMemberAvatar(
              name: member.name,
              avatarUrl: member.avatarUrl,
              radius: 40,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _InfoPill(
                icon: Icons.people_alt_rounded,
                label: member.relationship.label,
                background: scheme.surfaceContainerHighest,
                foreground: scheme.onSurfaceVariant,
              ),
              if (member.birthDate != null)
                _InfoPill(
                  icon: Icons.cake_outlined,
                  label: _ageText(member.birthDate!),
                  background: scheme.surfaceContainerHighest,
                  foreground: scheme.onSurfaceVariant,
                ),
              if (isActiveProfile)
                _InfoPill(
                  icon: Icons.check_circle_rounded,
                  label: 'Active Profile',
                  background: scheme.primaryContainer,
                  foreground: scheme.onPrimaryContainer,
                ),
            ],
          ),
          if (member.heightCm != null || member.weightKg != null) ...<Widget>[
            const SizedBox(height: 14),
            _BodyStats(heightCm: member.heightCm, weightKg: member.weightKg),
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

/// Lightweight rounded pill used for relationship, age and status metadata.
class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyStats extends StatelessWidget {
  const _BodyStats({this.heightCm, this.weightKg});

  final double? heightCm;
  final double? weightKg;

  /// Values outside these bounds are treated as placeholder / bad data and are
  /// hidden rather than rendered as a misleading "0 cm" measurement.
  static const double _minHeightCm = 30;
  static const double _maxHeightCm = 260;
  static const double _minWeightKg = 1;
  static const double _maxWeightKg = 400;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<Widget> pills = <Widget>[
      if (_isPlausible(heightCm, _minHeightCm, _maxHeightCm))
        _InfoPill(
          icon: Icons.height_rounded,
          label: '${_format(heightCm!)} cm',
          background: scheme.surfaceContainerHighest,
          foreground: scheme.onSurfaceVariant,
        ),
      if (_isPlausible(weightKg, _minWeightKg, _maxWeightKg))
        _InfoPill(
          icon: Icons.monitor_weight_outlined,
          label: '${_format(weightKg!)} kg',
          background: scheme.surfaceContainerHighest,
          foreground: scheme.onSurfaceVariant,
        ),
    ];

    if (pills.isEmpty) {
      return _InfoPill(
        icon: Icons.info_outline_rounded,
        label: 'Measurements not set',
        background: scheme.surfaceContainerHighest,
        foreground: scheme.onSurfaceVariant,
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: pills,
    );
  }

  static bool _isPlausible(double? value, double min, double max) {
    return value != null && value >= min && value <= max;
  }

  String _format(double value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
  }
}

/// Small square icon chip reused across the sizing and style sections.
class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    this.iconSize = 20,
    this.boxSize = 40,
  });

  final IconData icon;
  final double iconSize;
  final double boxSize;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(boxSize / 3),
      ),
      child: Icon(icon, size: iconSize, color: scheme.primary),
    );
  }
}

class _SizingCard extends StatelessWidget {
  const _SizingCard({required this.member});

  final FamilyMember member;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionTitle(
            icon: Icons.straighten_rounded,
            title: 'Sizing & Measurements',
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _StatTile(
                  icon: Icons.checkroom_rounded,
                  label: 'Tops',
                  value: member.topsSize,
                ),
              ),
              Expanded(
                child: _StatTile(
                  icon: Icons.straighten_rounded,
                  label: 'Bottoms',
                  value: member.bottomsSize,
                ),
              ),
              Expanded(
                child: _StatTile(
                  icon: Icons.do_not_step_rounded,
                  label: 'Shoes',
                  value: member.shoeSize == null
                      ? null
                      : '${member.shoeSize} ${member.shoeUnit}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _IconBadge(icon: icon, boxSize: 36, iconSize: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _StyleAestheticsCard extends StatelessWidget {
  const _StyleAestheticsCard({required this.member});

  final FamilyMember member;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionTitle(
            icon: Icons.auto_awesome_rounded,
            title: 'Style Aesthetics',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: member.styleAesthetics.map((String style) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.24),
                  ),
                ),
                child: Text(
                  _capitalizedName(style),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool hasValue = value != null && value!.trim().isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _IconBadge(icon: icon),
        const SizedBox(height: 10),
        Text(
          hasValue ? value! : 'Not set',
          maxLines: 1,
          textAlign: TextAlign.center,
          style: (hasValue
                  ? theme.textTheme.titleMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                    )
                  : theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ))
              ?.copyWith(
            // Keeps values such as "42.5 EU" from overflowing a narrow column.
            fontSize: hasValue ? null : theme.textTheme.bodyMedium?.fontSize,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
