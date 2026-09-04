import 'package:flutter/material.dart';

/// Destination descriptor for the app navigation bar.
class AppNavigationDestination {
  const AppNavigationDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.badgeCount = 0,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;

  /// When > 0 shows a small [Badge] on the destination icon.
  final int badgeCount;
}

/// Branded navigation bar for Digital Wardrobe.
///
/// Wraps Material's [NavigationBar] so every tab surface shares the same
/// themed look (defined centrally in `AppTheme.navigationBarTheme`). It is
/// purely presentational and never owns navigation state — callers pass the
/// selected index and an on-tap callback.
class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<AppNavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: destinations.map((AppNavigationDestination destination) {
        final bool showBadge = destination.badgeCount > 0;

        Widget buildDestination(IconData icon) => showBadge
            ? Badge(
                isLabelVisible: true,
                label: Text(
                  destination.badgeCount > 99
                      ? '99+'
                      : destination.badgeCount.toString(),
                ),
                child: Icon(icon),
              )
            : Icon(icon);

        return NavigationDestination(
          icon: buildDestination(destination.icon),
          selectedIcon: buildDestination(destination.selectedIcon),
          label: destination.label,
        );
      }).toList(),
    );
  }
}