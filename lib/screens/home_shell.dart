import 'package:flutter/material.dart';

import '../main.dart';
import 'map_screen.dart';
import 'explore_screen.dart';
import 'create_event_screen.dart';
import 'profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  final GlobalKey<MapScreenState> _mapKey = GlobalKey<MapScreenState>();
  final GlobalKey<ExploreScreenState> _exploreKey = GlobalKey<ExploreScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      MapScreen(key: _mapKey),
      ExploreScreen(key: _exploreKey),
      CreateEventScreen(
        onCreated: _onEventCreated,
      ),
      const ProfileScreen(),
    ];
  }

  void _onEventCreated() {
    _mapKey.currentState?.refresh();
    _exploreKey.currentState?.refresh();
    setState(() => _currentIndex = 0);
  }

  void _onTabChanged(int index) {
    setState(() => _currentIndex = index);
    switch (index) {
      case 0:
        _mapKey.currentState?.refresh();
        break;
      case 1:
        _exploreKey.currentState?.refresh();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? const Color(0xFF1A1A24).withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: 0.7);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.06);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    const items = [
      _NavItem(Icons.map_outlined, Icons.map, 'Map'),
      _NavItem(Icons.explore_outlined, Icons.explore, 'Explore'),
      _NavItem(Icons.add_circle_outline, Icons.add_circle, 'Create'),
      _NavItem(Icons.person_outline, Icons.person, 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 4,
        top: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isActive = _currentIndex == i;
          return GestureDetector(
            onTap: () => _onTabChanged(i),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: isActive ? kGradientPurplePink : null,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isActive ? item.activeIcon : item.icon,
                    size: 22,
                    color: isActive ? Colors.white : muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive
                        ? Theme.of(context).colorScheme.onSurface
                        : muted,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}
