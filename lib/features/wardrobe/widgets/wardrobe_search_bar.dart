import 'package:flutter/material.dart';

/// Quiet, editorial search bar for the wardrobe catalog.
///
/// Styled as an elegant rounded capsule matching the Figma design.
class WardrobeSearchBar extends StatelessWidget {
  const WardrobeSearchBar({
    super.key,
    required this.controller,
    required this.searchQuery,
    required this.onChanged,
    required this.onClear,
    this.hintText = 'Search Wardrobe',
  });

  final TextEditingController controller;
  final String searchQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE5E4DE),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF1C1C1E),
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: false,
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF8E8E93),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF8E8E93),
            size: 22,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 42,
            minHeight: 42,
          ),
          suffixIcon: searchQuery.trim().isEmpty
              ? null
              : IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Clear search',
                  visualDensity: VisualDensity.compact,
                ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
