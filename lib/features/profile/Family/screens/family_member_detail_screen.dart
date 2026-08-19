import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/data/models/growth_measurement.dart';
import 'package:digital_wardrobe_app/features/profile/widgets/family_member_avatar.dart';
import 'package:digital_wardrobe_app/features/profile/Family/widgets/add_growth_measurement_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FamilyMemberDetailScreen extends ConsumerWidget {
  const FamilyMemberDetailScreen({super.key, required this.member});

  final FamilyMember member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<FamilyMember?> updatedMember = ref.watch(
      familyMemberProvider(member.id),
    );

    final FamilyMember currentMember = updatedMember.valueOrNull ?? member;

    final bool isChild = currentMember.relationship == RelationshipType.child;

    return Scaffold(
      appBar: AppBar(title: Text(member.name)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(familyMemberProvider(member.id));
          ref.invalidate(familyMembersProvider);

          if (isChild) {
            ref.invalidate(growthMeasurementsProvider(member.id));
            await ref.read(growthMeasurementsProvider(member.id).future);
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            _MemberHeader(member: currentMember),
            if (isChild) _GrowthSection(member: currentMember),
          ],
        ),
      ),
    );
  }
}

class _GrowthSection extends ConsumerWidget {
  const _GrowthSection({required this.member});

  final FamilyMember member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<GrowthMeasurement>> measurements = ref.watch(
      growthMeasurementsProvider(member.id),
    );

    return Column(
      children: <Widget>[
        const SizedBox(height: 28),
        Text(
          'Current measurements',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        _CurrentMeasurementsCard(member: member),
        const SizedBox(height: 28),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Growth history',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            FilledButton.icon(
              onPressed: () async {
                await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AddGrowthMeasurementDialog(member: member);
                  },
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        measurements.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (Object error, StackTrace stackTrace) => const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Could not load growth history.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (List<GrowthMeasurement> items) {
            if (items.isEmpty) {
              return const _EmptyGrowthHistory();
            }

            return Column(
              children: items
                  .map(
                    (GrowthMeasurement measurement) =>
                        _MeasurementCard(measurement: measurement),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
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

class _CurrentMeasurementsCard extends StatelessWidget {
  const _CurrentMeasurementsCard({required this.member});

  final FamilyMember member;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            _MeasurementRow(
              icon: Icons.height,
              label: 'Height',
              value: member.heightCm == null
                  ? 'Not recorded'
                  : '${member.heightCm!.toStringAsFixed(1)} cm',
            ),
            const Divider(),
            _MeasurementRow(
              icon: Icons.monitor_weight_outlined,
              label: 'Weight',
              value: member.weightKg == null
                  ? 'Not recorded'
                  : '${member.weightKg!.toStringAsFixed(1)} kg',
            ),
            const Divider(),
            _MeasurementRow(
              icon: Icons.checkroom_outlined,
              label: 'Clothing size',
              value: member.currentSize ?? 'Not recorded',
            ),
            const Divider(),
            _MeasurementRow(
              icon: Icons.straighten_outlined,
              label: 'Foot length',
              value: member.footLengthCm == null
                  ? 'Not recorded'
                  : '${member.footLengthCm!.toStringAsFixed(1)} cm',
            ),
            const Divider(),
            _MeasurementRow(
              icon: Icons.directions_walk_outlined,
              label: 'Shoe size',
              value: member.shoeSize ?? 'Not recorded',
            ),
          ],
        ),
      ),
    );
  }
}

class _MeasurementRow extends StatelessWidget {
  const _MeasurementRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  const _MeasurementCard({required this.measurement});

  final GrowthMeasurement measurement;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _formatDate(measurement.recordedAt),
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 10,
              children: <Widget>[
                if (measurement.heightCm != null)
                  _HistoryValue(
                    label: 'Height',
                    value: '${measurement.heightCm!.toStringAsFixed(1)} cm',
                  ),
                if (measurement.weightKg != null)
                  _HistoryValue(
                    label: 'Weight',
                    value: '${measurement.weightKg!.toStringAsFixed(1)} kg',
                  ),
                if (measurement.clothingSize != null)
                  _HistoryValue(
                    label: 'Clothing',
                    value: measurement.clothingSize!,
                  ),
                if (measurement.footLengthCm != null)
                  _HistoryValue(
                    label: 'Foot length',
                    value: '${measurement.footLengthCm!.toStringAsFixed(1)} cm',
                  ),
                if (measurement.shoeSize != null)
                  _HistoryValue(label: 'Shoes', value: measurement.shoeSize!),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _HistoryValue extends StatelessWidget {
  const _HistoryValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _EmptyGrowthHistory extends StatelessWidget {
  const _EmptyGrowthHistory();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: <Widget>[
            Icon(
              Icons.show_chart,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'No measurements yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'Add measurements over time to build a growth history.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
