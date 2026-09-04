import 'package:flutter/material.dart';

/// Quiet, editorial search for the wardrobe catalog.
///
/// The field sits quietly under the header rather than demanding attention —
/// a subtle outlined surface with a leading search glyph and a trailing clear
/// action. Search behaviour (controller/onChanged/onClear) is unchanged.
class WardrobeSearchBar extends StatelessWidget {
  const WardrobeSearchBar({
    super.key,
    required this.controller,
    required this.searchQuery,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String searchQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search your closet',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: searchQuery.trim().isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close),
                tooltip: 'Clear search',
                visualDensity: VisualDensity.compact,
              ),
      ),
    );
  }
}