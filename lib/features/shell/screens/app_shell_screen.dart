import 'package:digital_wardrobe_app/features/alerts/screens/alerts_screen.dart';
import 'package:digital_wardrobe_app/features/analytics/screens/analytics_screen.dart';
import 'package:digital_wardrobe_app/features/calendar/screens/calendar_screen.dart';
import 'package:digital_wardrobe_app/features/outfits/screens/outfits_screen.dart';
import 'package:digital_wardrobe_app/features/profile/screens/profile_screen.dart';
import 'package:digital_wardrobe_app/features/wardrobe/screens/wardrobe_screen.dart';
import 'package:digital_wardrobe_app/data/models/alert.dart';
import 'package:digital_wardrobe_app/features/alerts/providers/alerts_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

class AppShellScreen extends ConsumerStatefulWidget {
  const AppShellScreen({super.key});

  @override
  ConsumerState<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends ConsumerState<AppShellScreen> {
  int _index = 0;
  static const List<Widget> _screens = <Widget>[
    WardrobeScreen(),
    OutfitsScreen(),
    CalendarScreen(),
    AlertsScreen(),
    AnalyticsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Alert>> alerts = ref.watch(alertsProvider);

    final int unreadCount = alerts.valueOrNull
        ?.where((Alert alert) => !alert.isRead)
        .length ??
        0;
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int value) => setState(() => _index = value),
        destinations: <NavigationDestination>[
          const NavigationDestination(
            icon: Icon(Icons.checkroom_outlined),
            selectedIcon: Icon(Icons.checkroom),
            label: 'Wardrobe',
          ),
          const NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Outfits',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
              ),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
              ),
              child: const Icon(Icons.notifications),
            ),
            label: 'Alerts',
          ),
          const NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Analytics',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
