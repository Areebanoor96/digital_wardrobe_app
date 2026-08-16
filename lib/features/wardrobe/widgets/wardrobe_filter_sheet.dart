import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/wardrobe/models/wardrobe_filters.dart';
import 'package:digital_wardrobe_app/features/wardrobe/providers/wardrobe_filter_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WardrobeFilterSheet extends ConsumerWidget {
  const WardrobeFilterSheet({super.key, required this.garments});

  final List<Garment> garments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final WardrobeFilters filters = ref.watch(wardrobeFilterProvider);

    final List<String> colors = _uniqueValues(
      garments.map((Garment garment) => garment.colorName),
    );

    final List<String> brands = _uniqueValues(
      garments.map((Garment garment) => garment.brand),
    );

    final List<String> sizes = _uniqueValues(
      garments.map((Garment garment) => garment.size),
    );

    final List<String> occasions = _uniqueListValues(
      garments.expand((Garment garment) => garment.occasions),
    );

    final List<String> seasons = _uniqueListValues(
      garments.expand((Garment garment) => garment.seasons),
    );

    final List<String> moods = _uniqueListValues(
      garments.expand((Garment garment) => garment.moods),
    );

    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        minChildSize: 0.55,
        maxChildSize: 0.95,
        builder: (BuildContext context, ScrollController scrollController) {
          return Column(
            children: <Widget>[
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: <Widget>[
                    const Expanded(
                      child: Text(
                        'Filter & Sort',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref
                            .read(wardrobeFilterProvider.notifier)
                            .clearFilters();
                      },
                      child: const Text('Clear filters'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: <Widget>[
                    _SectionTitle(
                      title: 'Sort by',
                      onClear:
                          filters.sortOption == WardrobeSortOption.newestAdded
                          ? null
                          : () {
                              ref
                                  .read(wardrobeFilterProvider.notifier)
                                  .setSortOption(
                                    WardrobeSortOption.newestAdded,
                                  );
                            },
                    ),
                    DropdownButtonFormField<WardrobeSortOption>(
                      initialValue: filters.sortOption,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.sort),
                      ),
                      items: WardrobeSortOption.values
                          .map(
                            (WardrobeSortOption option) =>
                                DropdownMenuItem<WardrobeSortOption>(
                                  value: option,
                                  child: Text(option.label),
                                ),
                          )
                          .toList(),
                      onChanged: (WardrobeSortOption? value) {
                        if (value == null) {
                          return;
                        }

                        ref
                            .read(wardrobeFilterProvider.notifier)
                            .setSortOption(value);
                      },
                    ),
                    const SizedBox(height: 24),

                    _FilterDropdown(
                      label: 'Color',
                      icon: Icons.palette_outlined,
                      value: filters.color,
                      values: colors,
                      onChanged: ref
                          .read(wardrobeFilterProvider.notifier)
                          .setColor,
                    ),
                    const SizedBox(height: 16),

                    _FilterDropdown(
                      label: 'Brand',
                      icon: Icons.sell_outlined,
                      value: filters.brand,
                      values: brands,
                      onChanged: ref
                          .read(wardrobeFilterProvider.notifier)
                          .setBrand,
                    ),
                    const SizedBox(height: 16),

                    _FilterDropdown(
                      label: 'Size',
                      icon: Icons.straighten_outlined,
                      value: filters.size,
                      values: sizes,
                      onChanged: ref
                          .read(wardrobeFilterProvider.notifier)
                          .setSize,
                    ),
                    const SizedBox(height: 16),

                    _FilterDropdown(
                      label: 'Occasion',
                      icon: Icons.celebration_outlined,
                      value: filters.occasion,
                      values: occasions,
                      onChanged: ref
                          .read(wardrobeFilterProvider.notifier)
                          .setOccasion,
                    ),
                    const SizedBox(height: 16),

                    _FilterDropdown(
                      label: 'Season',
                      icon: Icons.wb_sunny_outlined,
                      value: filters.season,
                      values: seasons,
                      onChanged: ref
                          .read(wardrobeFilterProvider.notifier)
                          .setSeason,
                    ),
                    const SizedBox(height: 16),

                    _FilterDropdown(
                      label: 'Mood',
                      icon: Icons.mood_outlined,
                      value: filters.mood,
                      values: moods,
                      onChanged: ref
                          .read(wardrobeFilterProvider.notifier)
                          .setMood,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<LaundryStatus?>(
                      initialValue: filters.laundryStatus,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.local_laundry_service_outlined),
                        labelText: 'Laundry status',
                      ),
                      items: <DropdownMenuItem<LaundryStatus?>>[
                        const DropdownMenuItem<LaundryStatus?>(
                          value: null,
                          child: Text('All laundry statuses'),
                        ),
                        ...LaundryStatus.values.map(
                          (LaundryStatus status) =>
                              DropdownMenuItem<LaundryStatus?>(
                                value: status,
                                child: Text(status.label),
                              ),
                        ),
                      ],
                      onChanged: ref
                          .read(wardrobeFilterProvider.notifier)
                          .setLaundryStatus,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      filters.activeFilterCount == 0
                          ? 'Show garments'
                          : 'Show garments · ${filters.activeFilterCount} filters',
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<String> _uniqueValues(Iterable<String?> values) {
    final Set<String> result = <String>{};

    for (final String? value in values) {
      final String cleaned = value?.trim() ?? '';

      if (cleaned.isNotEmpty) {
        result.add(cleaned);
      }
    }

    final List<String> sorted = result.toList()
      ..sort(
        (String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()),
      );

    return sorted;
  }

  List<String> _uniqueListValues(Iterable<String> values) {
    final Set<String> result = values
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toSet();

    final List<String> sorted = result.toList()
      ..sort(
        (String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()),
      );

    return sorted;
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final String? value;
  final List<String> values;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      initialValue: values.contains(value) ? value : null,
      decoration: InputDecoration(prefixIcon: Icon(icon), labelText: label),
      items: <DropdownMenuItem<String?>>[
        DropdownMenuItem<String?>(
          value: null,
          child: Text('All ${label.toLowerCase()}s'),
        ),
        ...values.map(
          (String item) =>
              DropdownMenuItem<String?>(value: item, child: Text(item)),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.onClear});

  final String title;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (onClear != null)
          TextButton(onPressed: onClear, child: const Text('Reset')),
      ],
    );
  }
}
