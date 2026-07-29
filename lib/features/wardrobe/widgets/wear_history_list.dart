import 'package:digital_wardrobe_app/data/models/wear_log.dart';
import 'package:flutter/material.dart';

class WearHistoryList extends StatelessWidget {
  const WearHistoryList({super.key, required this.history});
  final List<WearLog> history;

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
        ),
      )
          .toList(),
    );
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
