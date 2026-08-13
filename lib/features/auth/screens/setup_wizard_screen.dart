import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/core/services/profile_session_service.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/data/models/profile.dart';
import 'package:digital_wardrobe_app/features/alerts/providers/alerts_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SetupWizardScreen extends ConsumerStatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  ConsumerState<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends ConsumerState<SetupWizardScreen> {
  final PageController _controller = PageController();
  int _step = 0;
  bool _saving = false;
  bool _loadedProfile = false;

  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _memberNameController = TextEditingController();

  RelationshipType _relationship = RelationshipType.self;
  bool _unusedAlerts = true;
  bool _laundryAlerts = true;
  bool _ootdAlerts = true;
  bool _growthAlerts = true;

  @override
  void dispose() {
    _controller.dispose();
    _cityController.dispose();
    _memberNameController.dispose();
    super.dispose();
  }

  void _applyProfile(Profile profile) {
    if (_loadedProfile) {
      return;
    }

    _loadedProfile = true;
    _cityController.text = profile.locationCity ?? '';
    _unusedAlerts = profile.unusedAlertsEnabled;
    _laundryAlerts = profile.laundryAlertsEnabled;
    _ootdAlerts = profile.ootdAlertsEnabled;
    _growthAlerts = profile.growthAlertsEnabled;
  }

  void _next() {
    if (_step == 2) {
      _finish();
      return;
    }

    _controller.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    if (_saving) {
      return;
    }

    setState(() => _saving = true);

    try {
      final String city = _cityController.text.trim();

      await ref.read(profileRepositoryProvider).updateLocationCity(
        city.isEmpty ? null : city,
      );

      await ref.read(profileRepositoryProvider).updateAlertPreferences(
        unusedAlertsEnabled: _unusedAlerts,
        laundryAlertsEnabled: _laundryAlerts,
        ootdAlertsEnabled: _ootdAlerts,
        growthAlertsEnabled: _growthAlerts,
      );

      ref.invalidate(profileProvider);
      ref.invalidate(alertsProvider);

      FamilyMember? createdMember;
      final String memberName = _memberNameController.text.trim();

      if (memberName.isNotEmpty) {
        createdMember = await ref
            .read(familyRepositoryProvider)
            .addFamilyMember(
              name: memberName,
              relationship: _relationship.name,
            );
        ref.invalidate(familyMembersProvider);
      }

      await _selectMemberAndEnterApp(preferred: createdMember);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not finish setup: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _skip() async {
    if (_saving) {
      return;
    }

    try {
      final List<FamilyMember> members = await ref
          .read(familyRepositoryProvider)
          .fetchFamilyMembers();

      if (members.isNotEmpty) {
        final FamilyMember member = members.first;
        ref.read(selectedFamilyMemberProvider.notifier).state = member;
        await ProfileSessionService.saveSelectedProfile(member.id);
      }
    } catch (_) {
      // Best effort: with no selected member the router falls back to /profiles.
    }

    if (!mounted) {
      return;
    }

    context.go('/app');
  }

  Future<void> _selectMemberAndEnterApp({FamilyMember? preferred}) async {
    FamilyMember? selected = preferred;

    if (selected == null) {
      final List<FamilyMember> members = await ref
          .read(familyRepositoryProvider)
          .fetchFamilyMembers();

      if (members.isNotEmpty) {
        selected = members.first;
      }
    }

    if (selected != null) {
      ref.read(selectedFamilyMemberProvider.notifier).state = selected;
      await ProfileSessionService.saveSelectedProfile(selected.id);
    }

    if (mounted) {
      context.go('/app');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Profile> profile = ref.watch(profileProvider);

    ref.listen<AsyncValue<Profile>>(
      profileProvider,
      (AsyncValue<Profile>? previous, AsyncValue<Profile> next) {
        if (next is AsyncData<Profile>) {
          _applyProfile(next.value);
        }
      },
    );

    return Scaffold(
      body: SafeArea(
        child: profile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('Could not load your setup.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(profileProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (Profile profile) {
            _applyProfile(profile);

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _saving ? null : _skip,
                      child: const Text('Skip setup'),
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _controller,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (int step) => setState(() => _step = step),
                      children: <Widget>[
                        _SetupStep(
                          icon: Icons.location_city_outlined,
                          title: 'Where are you based?',
                          description:
                              'Add your city to prepare weather-aware outfit suggestions.',
                          child: TextField(
                            controller: _cityController,
                            enabled: !_saving,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'City',
                              hintText: 'For example: Islamabad',
                              prefixIcon: Icon(Icons.location_city_outlined),
                            ),
                          ),
                        ),
                        _SetupStep(
                          icon: Icons.people_outline,
                          title: 'Who is in your wardrobe?',
                          description:
                              'Add a family member now if you like. '
                              'You can manage more people later.',
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              TextField(
                                controller: _memberNameController,
                                enabled: !_saving,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Family member name',
                                  hintText: 'Optional for now',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<RelationshipType>(
                                initialValue: _relationship,
                                decoration: const InputDecoration(
                                  labelText: 'Relationship',
                                  prefixIcon: Icon(
                                    Icons.family_restroom_outlined,
                                  ),
                                ),
                                items: RelationshipType.values
                                    .map(
                                      (RelationshipType type) =>
                                          DropdownMenuItem<RelationshipType>(
                                            value: type,
                                            child: Text(type.label),
                                          ),
                                    )
                                    .toList(),
                                onChanged: _saving
                                    ? null
                                    : (RelationshipType? value) {
                                        if (value == null) {
                                          return;
                                        }

                                        setState(() {
                                          _relationship = value;
                                        });
                                      },
                              ),
                            ],
                          ),
                        ),
                        _SetupStep(
                          icon: Icons.notifications_none_rounded,
                          title: 'Stay in the loop',
                          description: 'Choose the in-app alerts you want.',
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                secondary: const Icon(
                                  Icons.watch_later_outlined,
                                ),
                                title: const Text('Unused garment alerts'),
                                subtitle: const Text(
                                  'Remind me about clothes I have not worn.',
                                ),
                                value: _unusedAlerts,
                                onChanged: _saving
                                    ? null
                                    : (bool value) => setState(
                                          () => _unusedAlerts = value,
                                        ),
                              ),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                secondary: const Icon(
                                  Icons.local_laundry_service_outlined,
                                ),
                                title: const Text('Laundry alerts'),
                                subtitle: const Text(
                                  'Remind me when garments need washing.',
                                ),
                                value: _laundryAlerts,
                                onChanged: _saving
                                    ? null
                                    : (bool value) => setState(
                                          () => _laundryAlerts = value,
                                        ),
                              ),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                secondary: const Icon(
                                  Icons.auto_awesome_outlined,
                                ),
                                title: const Text('Outfit of the Day'),
                                subtitle: const Text(
                                  'Suggest a fresh outfit every day.',
                                ),
                                value: _ootdAlerts,
                                onChanged: _saving
                                    ? null
                                    : (bool value) => setState(
                                          () => _ootdAlerts = value,
                                        ),
                              ),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                secondary: const Icon(Icons.trending_up),
                                title: const Text('Kids growth alerts'),
                                subtitle: const Text(
                                  'Remind me about sizes and measurements.',
                                ),
                                value: _growthAlerts,
                                onChanged: _saving
                                    ? null
                                    : (bool value) => setState(
                                          () => _growthAlerts = value,
                                        ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _saving ? null : _next,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_step == 2 ? 'Finish' : 'Continue'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SetupStep extends StatelessWidget {
  const _SetupStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 24),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(description, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        child,
      ],
    );
  }
}