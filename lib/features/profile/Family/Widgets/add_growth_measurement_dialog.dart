import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/features/alerts/providers/alerts_provider.dart'
    as alerts;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddGrowthMeasurementDialog extends ConsumerStatefulWidget {
  const AddGrowthMeasurementDialog({super.key, required this.member});

  final FamilyMember member;

  @override
  ConsumerState<AddGrowthMeasurementDialog> createState() =>
      _AddGrowthMeasurementDialogState();
}

const List<String> kChildClothingSizes = <String>[
  '0–1 Years',
  '1–2 Years',
  '2–3 Years',
  '3–4 Years',
  '4–5 Years',
  '5–6 Years',
  '6–7 Years',
  '7–8 Years',
  '8–9 Years',
  '9–10 Years',
  '10–11 Years',
  '11–12 Years',
  '12–13 Years',
  '13–14 Years',
  '14–15 Years',
  '15–16 Years',
  '16–17 Years',
];

const List<String> kShoeSizeSystems = <String>['UK/PK', 'US', 'EU'];

class _AddGrowthMeasurementDialogState
    extends ConsumerState<AddGrowthMeasurementDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _footLengthController;
  late final TextEditingController _shoeValueController;

  DateTime _recordedAt = DateTime.now();
  String? _selectedClothingSize;
  String? _selectedShoeSystem;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _footLengthController = TextEditingController();

    final String? memberCurrentSize = widget.member.currentSize;
    _selectedClothingSize = kChildClothingSizes.contains(memberCurrentSize)
        ? memberCurrentSize
        : null;

    final String? memberShoeSize = widget.member.shoeSize;
    String? shoeSystem;
    String? shoeValue;

    if (memberShoeSize != null && memberShoeSize.trim().isNotEmpty) {
      for (final String system in kShoeSizeSystems) {
        if (memberShoeSize.startsWith('$system ')) {
          shoeSystem = system;
          shoeValue = memberShoeSize.substring(system.length + 1).trim();
          break;
        }
      }

      if (shoeSystem == null) {
        shoeValue = memberShoeSize;
      }
    }

    _selectedShoeSystem = shoeSystem ?? kShoeSizeSystems.first;
    _shoeValueController = TextEditingController(text: shoeValue ?? '');
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _footLengthController.dispose();
    _shoeValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add measurement for ${widget.member.name}'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Measurement date'),
                  subtitle: Text(_formatDate(_recordedAt)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: _selectDate,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _heightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Height',
                    suffixText: 'cm',
                    prefixIcon: Icon(Icons.height),
                  ),
                  validator: (String? value) =>
                      _validateNumber(value, 'height'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Weight',
                    suffixText: 'kg',
                    prefixIcon: Icon(Icons.monitor_weight_outlined),
                  ),
                  validator: (String? value) =>
                      _validateNumber(value, 'weight'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedClothingSize,
                  decoration: const InputDecoration(
                    labelText: 'Clothing size',
                    prefixIcon: Icon(Icons.checkroom_outlined),
                  ),
                  items: kChildClothingSizes.map((String size) {
                    return DropdownMenuItem<String>(
                      value: size,
                      child: Text(size),
                    );
                  }).toList(),
                  onChanged: _isSaving
                      ? null
                      : (String? value) {
                          setState(() {
                            _selectedClothingSize = value;
                          });
                        },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _footLengthController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Foot length',
                    suffixText: 'cm',
                    prefixIcon: Icon(Icons.straighten_outlined),
                  ),
                  validator: (String? value) =>
                      _validateNumber(value, 'foot length'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedShoeSystem,
                        decoration: const InputDecoration(
                          labelText: 'Shoe size system',
                          prefixIcon: Icon(Icons.directions_walk_outlined),
                        ),
                        items: kShoeSizeSystems.map((String system) {
                          return DropdownMenuItem<String>(
                            value: system,
                            child: Text(system),
                          );
                        }).toList(),
                        onChanged: _isSaving
                            ? null
                            : (String? value) {
                                if (value == null) {
                                  return;
                                }

                                setState(() {
                                  _selectedShoeSystem = value;
                                });
                              },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _shoeValueController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Shoe size',
                          prefixIcon: Icon(Icons.straighten_outlined),
                        ),
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }

                          final double? number = double.tryParse(value.trim());

                          if (number == null || number <= 0) {
                            return 'Enter a valid shoe size';
                          }

                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: widget.member.birthDate ?? DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      _recordedAt = selectedDate;
    });
  }

  String? _validateNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final double? number = double.tryParse(value.trim());

    if (number == null || number <= 0) {
      return 'Enter a valid $fieldName';
    }

    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String heightText = _heightController.text.trim();
    final String weightText = _weightController.text.trim();
    final String footLengthText = _footLengthController.text.trim();
    final String shoeValue = _shoeValueController.text.trim();
    final String? clothingSize = _selectedClothingSize;
    final String? shoeSize = shoeValue.isEmpty
        ? null
        : '${_selectedShoeSystem ?? kShoeSizeSystems.first} $shoeValue';

    if (heightText.isEmpty &&
        weightText.isEmpty &&
        footLengthText.isEmpty &&
        clothingSize == null &&
        shoeSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one measurement.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(growthRepositoryProvider)
          .addMeasurement(
            memberId: widget.member.id,
            recordedAt: _recordedAt,
            heightCm: heightText.isEmpty ? null : double.parse(heightText),
            weightKg: weightText.isEmpty ? null : double.parse(weightText),
            clothingSize: clothingSize,
            shoeSize: shoeSize,
            footLengthCm: footLengthText.isEmpty
                ? null
                : double.parse(footLengthText),
          );

      ref.invalidate(growthMeasurementsProvider(widget.member.id));

      ref.invalidate(familyMembersProvider);
      ref.invalidate(familyMemberProvider(widget.member.id));
      ref.invalidate(alerts.alertsProvider);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save measurement: $error')),
        );

        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
