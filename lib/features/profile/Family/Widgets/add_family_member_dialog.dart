import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddFamilyMemberDialog extends ConsumerStatefulWidget {
  const AddFamilyMemberDialog({super.key, this.member});

  final FamilyMember? member;
  @override
  ConsumerState<AddFamilyMemberDialog> createState() =>
      _AddFamilyMemberDialogState();
}

bool isChildBirthDateValid({
  required RelationshipType relationship,
  required DateTime? birthDate,
}) {
  return relationship != RelationshipType.child || birthDate != null;
}

class _AddFamilyMemberDialogState extends ConsumerState<AddFamilyMemberDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  RelationshipType _relationship = RelationshipType.self;
  DateTime? _birthDate;
  bool _isSaving = false;

  Uint8List? _selectedAvatarBytes;
  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    if (widget.member != null) {
      _nameController.text = widget.member!.name;
      _relationship = widget.member!.relationship;
      _birthDate = widget.member!.birthDate;
      _heightController.text = _numberOrEmpty(widget.member!.heightCm);
      _weightController.text = _numberOrEmpty(widget.member!.weightKg);
    }
  }

  static String _numberOrEmpty(double? value) {
    if (value == null) {
      return '';
    }

    return value % 1 == 0
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  Future<void> _pickAvatar({required bool fromCamera}) async {
    final imageService = ref.read(imageServiceProvider);

    final image = fromCamera
        ? await imageService.takePhoto()
        : await imageService.pickFromGallery();

    if (image == null) {
      return;
    }

    final bytes = await imageService.readBytes(image);

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedAvatarBytes = bytes;
    });
  }

  Future<void> _showAvatarOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take photo'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAvatar(fromCamera: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAvatar(fromCamera: false);
                },
              ),
              if (_selectedAvatarBytes != null ||
                  widget.member?.avatarUrl != null)
                ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Remove photo',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);

                    setState(() {
                      _selectedAvatarBytes = null;
                    });

                    if (widget.member != null &&
                        widget.member!.avatarPath != null) {
                      await ref
                          .read(familyRepositoryProvider)
                          .removeAvatar(widget.member!);

                      ref.invalidate(familyMembersProvider);
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.member == null ? 'Add Family Member' : 'Edit Family Member',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isSaving ? null : _showAvatarOptions,
                    child: CircleAvatar(
                      radius: 42,
                      backgroundImage: _selectedAvatarBytes != null
                          ? MemoryImage(_selectedAvatarBytes!)
                          : (widget.member?.avatarUrl != null
                          ? NetworkImage(widget.member!.avatarUrl!)
                          : null)
                      as ImageProvider?,
                      child:
                      (_selectedAvatarBytes == null &&
                          widget.member?.avatarUrl == null)
                          ? const Icon(Icons.add_a_photo_outlined, size: 28)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (_selectedAvatarBytes == null && widget.member?.avatarUrl == null)
                        ? 'Add photo (optional)'
                        : 'Change photo',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<RelationshipType>(
              initialValue: _relationship,
              decoration: const InputDecoration(labelText: 'Relationship'),
              items: RelationshipType.values.map((type) {
                return DropdownMenuItem(value: type, child: Text(type.label));
              }).toList(),
              onChanged: _isSaving
                  ? null
                  : (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _relationship = value;
                      });
                    },
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _heightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Height (cm)',
                      hintText: 'Optional',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Weight (kg)',
                      hintText: 'Optional',
                    ),
                  ),
                ),
              ],
            ),
            if (_relationship == RelationshipType.child) ...<Widget>[
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.cake_outlined),
                title: const Text('Date of birth (required)'),
                subtitle: Text(
                  _birthDate == null
                      ? 'Select date of birth'
                      : _formatDate(_birthDate!),
                ),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: _isSaving ? null : _selectBirthDate,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving
              ? null
              : () {
                  Navigator.pop(context);
                },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _saveMember,
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

  Future<void> _selectBirthDate() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2015),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      _birthDate = selectedDate;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  double? _parseOptionalNumber(String value) {
    final String trimmed = value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    final double? parsed = double.tryParse(trimmed);

    if (parsed == null || parsed < 0) {
      return null;
    }

    return parsed;
  }

  Future<void> _saveMember() async {
    final String name = _nameController.text.trim();

    if (name.isEmpty || _isSaving) {
      return;
    }

    final double? heightCm = _parseOptionalNumber(_heightController.text);
    final double? weightKg = _parseOptionalNumber(_weightController.text);

    if (heightCm == null && _heightController.text.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid height.')),
      );
      return;
    }

    if (weightKg == null && _weightController.text.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid weight.')),
      );
      return;
    }

    if (!isChildBirthDateValid(
      relationship: _relationship,
      birthDate: _birthDate,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Date of birth is required for a child.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.member == null) {
        // Add new family member
        await ref
            .read(familyRepositoryProvider)
            .addFamilyMember(
              name: name,
              relationship: _relationship.name,
              avatarBytes: _selectedAvatarBytes,
              birthDate: _birthDate,
              heightCm: heightCm,
              weightKg: weightKg,
            );
      } else {
        // Update existing family member
        await ref
            .read(familyRepositoryProvider)
            .updateFamilyMember(
              id: widget.member!.id,
              name: name,
              relationship: _relationship.name,
              birthDate: _birthDate,
              heightCm: heightCm,
              weightKg: weightKg,
            );

        // Upload new avatar if user selected one
        if (_selectedAvatarBytes != null) {
          await ref
              .read(familyRepositoryProvider)
              .updateAvatar(
                memberId: widget.member!.id,
                bytes: _selectedAvatarBytes!,
              );
        }
      }

      ref.invalidate(familyMembersProvider);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add family member: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
