import 'package:digital_wardrobe_app/data/models/shoe_size.dart';
import 'package:digital_wardrobe_app/features/profile/Family/Widgets/shoe_size_picker.dart';
import 'package:flutter/material.dart';

/// Dialog for viewing and changing a family member's shoe size.
///
/// Pops with a `(ShoeSize? size, bool remove)` record:
///  - `(null, false)` — cancelled / no change (keep the existing value)
///  - `(size, false)` — save/replace the value
///  - `(null, true)` — explicitly remove the recorded size
typedef ShoeSizeEditResult = (ShoeSize? size, bool remove);

class EditShoeSizeDialog extends StatefulWidget {
  const EditShoeSizeDialog({super.key, this.initial});

  final ShoeSize? initial;

  @override
  State<EditShoeSizeDialog> createState() => _EditShoeSizeDialogState();
}

class _EditShoeSizeDialogState extends State<EditShoeSizeDialog> {
  ShoeSize? _selected;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Shoe size'),
      scrollable: true,
      content: ShoeSizePicker(
        initial: widget.initial,
        onChanged: (ShoeSize? value) {
          _selected = value;
        },
      ),
      actions: <Widget>[
        if (widget.initial != null)
          TextButton(
            onPressed: () => Navigator.pop(context, (null, true)),
            child: const Text('Remove size'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context, (null, false)),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            (_selected ?? widget.initial, false),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}