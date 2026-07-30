import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddFamilyMemberDialog extends ConsumerStatefulWidget {
  const AddFamilyMemberDialog({super.key});

  @override
  ConsumerState<AddFamilyMemberDialog> createState() =>
      _AddFamilyMemberDialogState();
}

class _AddFamilyMemberDialogState
    extends ConsumerState<AddFamilyMemberDialog> {
  final TextEditingController _nameController = TextEditingController();

  RelationshipType _relationship = RelationshipType.self;
  bool _isSaving = false;

  Uint8List? _selectedAvatarBytes;
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
              if (_selectedAvatarBytes != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Remove photo'),
                  onTap: () {
                    Navigator.pop(sheetContext);

                    setState(() {

                      _selectedAvatarBytes = null;
                    });
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
      title: const Text('Add Family Member'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _isSaving ? null : _showAvatarOptions,
              child: CircleAvatar(
                radius: 42,
                backgroundImage: _selectedAvatarBytes != null
                    ? MemoryImage(_selectedAvatarBytes!)
                    : null,
                child: _selectedAvatarBytes == null
                    ? const Icon(
                  Icons.add_a_photo_outlined,
                  size: 28,
                )
                    : null,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _selectedAvatarBytes == null
                  ? 'Add photo (optional)'
                  : 'Change photo',
            ),

            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<RelationshipType>(
              initialValue: _relationship,
              decoration: const InputDecoration(
                labelText: 'Relationship',
              ),
              items: RelationshipType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.label),
                );
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
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _saveMember() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref.read(familyRepositoryProvider).addFamilyMember(
        name: name,
        relationship: _relationship.name,
      );

      ref.invalidate(familyMembersProvider);

      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}