import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddGrowthMeasurementDialog extends ConsumerStatefulWidget {
  const AddGrowthMeasurementDialog({super.key, required this.member});

  final FamilyMember member;

  @override
  ConsumerState<AddGrowthMeasurementDialog> createState() =>
      _AddGrowthMeasurementDialogState();
}

class _AddGrowthMeasurementDialogState
    extends ConsumerState<AddGrowthMeasurementDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _clothingSizeController;
  late final TextEditingController _shoeSizeController;

  DateTime _recordedAt = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _clothingSizeController = TextEditingController(
      text: widget.member.currentSize ?? '',
    );
    _shoeSizeController = TextEditingController(
      text: widget.member.shoeSize ?? '',
    );
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _clothingSizeController.dispose();
    _shoeSizeController.dispose();
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
                TextFormField(
                  controller: _clothingSizeController,
                  decoration: const InputDecoration(
                    labelText: 'Clothing size',
                    prefixIcon: Icon(Icons.checkroom_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _shoeSizeController,
                  decoration: const InputDecoration(
                    labelText: 'Shoe size',
                    prefixIcon: Icon(Icons.directions_walk_outlined),
                  ),
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
    final String clothingSize = _clothingSizeController.text.trim();
    final String shoeSize = _shoeSizeController.text.trim();

    if (heightText.isEmpty &&
        weightText.isEmpty &&
        clothingSize.isEmpty &&
        shoeSize.isEmpty) {
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
            clothingSize: clothingSize.isEmpty ? null : clothingSize,
            shoeSize: shoeSize.isEmpty ? null : shoeSize,
          );

      ref.invalidate(growthMeasurementsProvider(widget.member.id));

      ref.invalidate(familyMembersProvider);
      ref.invalidate(familyMemberProvider(widget.member.id));
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
