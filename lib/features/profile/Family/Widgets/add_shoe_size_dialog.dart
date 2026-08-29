import 'package:digital_wardrobe_app/data/models/shoe_size.dart';
import 'package:flutter/material.dart';

/// Dialog for entering a custom shoe size for a given [system].
///
/// Triggered by the `Other` option in [ShoeSizePicker]. Pops with the
/// entered value on success; [existing] is used to reject duplicates.
class AddShoeSizeDialog extends StatefulWidget {
  const AddShoeSizeDialog({
    super.key,
    required this.system,
    this.existing = const <String>{},
  });

  final ShoeSizeSystem system;
  final Set<String> existing;

  @override
  State<AddShoeSizeDialog> createState() => _AddShoeSizeDialogState();
}

class _AddShoeSizeDialogState extends State<AddShoeSizeDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Shoe Size'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Enter a custom size in ${widget.system.label} sizing '
            '(e.g. 41.5, 3W).',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Shoe size',
            ).copyWith(errorText: _errorText),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _submit() {
    final String value = _controller.text.trim();

    if (value.isEmpty) {
      setState(() {
        _errorText = 'Enter a shoe size';
      });
      return;
    }

    final bool duplicate = widget.existing.any(
      (String size) => size.toLowerCase() == value.toLowerCase(),
    );

    if (duplicate) {
      setState(() {
        _errorText = 'This size is already listed';
      });
      return;
    }

    Navigator.pop(context, value);
  }
}