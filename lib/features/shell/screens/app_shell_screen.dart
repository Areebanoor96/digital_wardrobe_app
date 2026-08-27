import 'package:digital_wardrobe_app/features/alerts/screens/alerts_screen.dart';
import 'package:digital_wardrobe_app/features/analytics/screens/analytics_screen.dart';
import 'package:digital_wardrobe_app/features/calendar/screens/calendar_screen.dart';
import 'package:digital_wardrobe_app/features/outfits/screens/outfits_screen.dart';
import 'package:digital_wardrobe_app/features/profile/screens/profile_screen.dart';
import 'package:digital_wardrobe_app/features/wardrobe/screens/wardrobe_screen.dart';
import 'package:digital_wardrobe_app/data/models/alert.dart';
import 'package:digital_wardrobe_app/features/alerts/providers/alerts_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppShellScreen extends ConsumerStatefulWidget {
  const AppShellScreen({super.key});

  @override
  ConsumerState<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends ConsumerState<AppShellScreen> {
  static const Duration _exitConfirmationWindow = Duration(seconds: 2);

  int _index = 0;
  final List<int> _tabHistory = <int>[0];
  DateTime? _lastBackPressAt;

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  void _handleBackPress(bool didPop, Object? result) {
    if (didPop) {
      return;
    }

    if (_navigateToPreviousTab()) {
      return;
    }

    if (!_isAndroid) {
      return;
    }

    final DateTime now = DateTime.now();
    final DateTime? lastPress = _lastBackPressAt;

    if (lastPress == null ||
        now.difference(lastPress) > _exitConfirmationWindow) {
      _lastBackPressAt = now;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Press back again to exit.')),
        );
      return;
    }

    SystemNavigator.pop();
  }

  void _selectTab(int value) {
    if (value == _index) {
      return;
    }

    setState(() {
      _index = value;
      _tabHistory
        ..remove(value)
        ..add(value);
      _lastBackPressAt = null;
    });
  }

  bool _navigateToPreviousTab() {
    if (_tabHistory.length <= 1) {
      return false;
    }

    setState(() {
      _tabHistory.removeLast();
      _index = _tabHistory.last;
      _lastBackPressAt = null;
    });

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Alert>> alerts = ref.watch(alertsProvider);

    final int unreadCount = alerts.valueOrNull
        ?.where((Alert alert) => !alert.isRead)
        .length ??
        0;
    final bool canNavigateBack = _tabHistory.length > 1;
    final List<Widget> screens = <Widget>[
      WardrobeScreen(
        canNavigateBack: canNavigateBack,
        onNavigateBack: _navigateToPreviousTab,
      ),
      OutfitsScreen(
        canNavigateBack: canNavigateBack,
        onNavigateBack: _navigateToPreviousTab,
      ),
      CalendarScreen(
        canNavigateBack: canNavigateBack,
        onNavigateBack: _navigateToPreviousTab,
      ),
      AlertsScreen(
        canNavigateBack: canNavigateBack,
        onNavigateBack: _navigateToPreviousTab,
      ),
      AnalyticsScreen(
        canNavigateBack: canNavigateBack,
        onNavigateBack: _navigateToPreviousTab,
      ),
      ProfileScreen(
        canNavigateBack: canNavigateBack,
        onNavigateBack: _navigateToPreviousTab,
      ),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handleBackPress,
      child: Scaffold(
        body: IndexedStack(index: _index, children: screens),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _selectTab,
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
      ),
    );
  }
}
