import 'package:digital_wardrobe_app/data/models/shoe_size.dart';
import 'package:digital_wardrobe_app/features/profile/Family/widgets/add_shoe_size_dialog.dart';
import 'package:flutter/material.dart';

/// Catalog-style shoe-size selector for a family member profile.
///
/// Follows the garment-size pattern: a canonical list of values is offered as
/// selectable chips for the chosen sizing system, previously saved custom
/// values are preserved, and an `Other` option opens a free-text flow. Unlike
/// garments (multi-select), a person has a single shoe size, so selection is
/// single-select.
class ShoeSizePicker extends StatefulWidget {
  const ShoeSizePicker({super.key, this.initial, this.onChanged});

  /// Previously saved value, used to restore the selected system/value.
  final ShoeSize? initial;

  /// Called whenever the selection changes. Passes `null` when the picker is
  /// reset (e.g. after switching sizing system).
  final ValueChanged<ShoeSize?>? onChanged;

  @override
  State<ShoeSizePicker> createState() => _ShoeSizePickerState();
}

class _ShoeSizePickerState extends State<ShoeSizePicker> {
  late ShoeSizeSystem _system;
  String? _selectedValue;

  /// Extra (custom) sizes per system, kept separate so a saved custom value
  /// survives a system switch.
  final Map<ShoeSizeSystem, List<String>> _customValues =
      <ShoeSizeSystem, List<String>>{};

  @override
  void initState() {
    super.initState();

    final ShoeSize? initial = widget.initial;
    _system = initial?.system ?? ShoeSizeSystem.eu;
    _selectedValue = initial?.value;

    if (initial != null &&
        !ShoeSizeCatalog.sizesFor(initial.system).contains(initial.value)) {
      _customValues[initial.system] = <String>[initial.value];
    }
  }

  void _emit() {
    final String? value = _selectedValue;
    widget.onChanged?.call(
      value == null ? null : ShoeSize(system: _system, value: value),
    );
  }

  void _selectSystem(ShoeSizeSystem? system) {
    if (system == null || system == _system) {
      return;
    }

    setState(() {
      _system = system;
      _selectedValue = null;
    });
    _emit();
  }

  void _selectValue(String value) {
    if (_selectedValue == value) {
      return;
    }

    setState(() {
      _selectedValue = value;
    });
    _emit();
  }

  Future<void> _addCustomSize() async {
    final List<String> existing = <String>[
      ...ShoeSizeCatalog.sizesFor(_system),
      ...?_customValues[_system],
    ];

    final String? value = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AddShoeSizeDialog(system: _system, existing: existing.toSet());
      },
    );

    if (value == null || !mounted) {
      return;
    }

    setState(() {
      (_customValues[_system] ??= <String>[]).add(value);
      _selectedValue = value;
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<String> options = <String>[
      ...ShoeSizeCatalog.sizesFor(_system),
      ...?_customValues[_system],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DropdownButtonFormField<ShoeSizeSystem>(
          initialValue: _system,
          decoration: const InputDecoration(
            labelText: 'Shoe size system',
            prefixIcon: Icon(Icons.directions_walk_outlined),
          ),
          items: ShoeSizeSystem.values
              .map(
                (ShoeSizeSystem system) => DropdownMenuItem<ShoeSizeSystem>(
                  value: system,
                  child: Text(system.label),
                ),
              )
              .toList(),
          onChanged: _selectSystem,
        ),
        const SizedBox(height: 6),
        Text(
          ShoeSizeCatalog.hintFor(_system),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Shoe size',
            hintText: 'Optional',
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final String size in options)
                ChoiceChip(
                  label: Text(size),
                  selected: _selectedValue == size,
                  onSelected: (_) => _selectValue(size),
                ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 18),
                label: const Text('Other'),
                onPressed: _addCustomSize,
              ),
            ],
          ),
        ),
      ],
    );
  }
}