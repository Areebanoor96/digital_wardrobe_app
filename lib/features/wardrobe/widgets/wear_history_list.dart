import 'package:digital_wardrobe_app/data/models/wear_log.dart';
import 'package:flutter/material.dart';

class WearHistoryList extends StatelessWidget {
  const WearHistoryList({
    super.key,
    required this.history,
    required this.onDelete,
  });

  final List<WearLog> history;

  /// Called after the user confirms deletion of a [WearLog].
  final ValueChanged<WearLog> onDelete;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Text(
        'No wear history yet. Mark this garment as worn to start tracking it.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return Column(
      children: history
          .map(
            (WearLog entry) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_available_outlined),
              title: Text(_formatDate(entry.wornDate)),
              subtitle: _subtitle(entry),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete wear record',
                onPressed: () => _confirmDelete(context, entry),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget? _subtitle(WearLog entry) {
    final List<String> parts = <String>[
      if (entry.eventName != null) entry.eventName!,
      if (entry.notes != null) entry.notes!,
    ];

    if (parts.isEmpty) {
      return null;
    }

    return Text(parts.join(' \u00b7 '));
  }

  Future<void> _confirmDelete(BuildContext context, WearLog entry) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Delete this wear record?'),
        content: Text(
          'The wear on '
          '${_formatDate(entry.wornDate)} will be removed and the '
          'garment\u2019s wear count and last-worn date will be updated.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onDelete(entry);
    }
  }

  String _formatDate(DateTime date) =>
      '${_monthName(date.month)} ${date.day}, ${date.year}';

  String _monthName(int month) => const <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];
}