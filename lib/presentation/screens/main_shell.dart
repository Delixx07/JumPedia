import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';

/// ═══════════════════════════════════════
/// MAIN SHELL — JumPedia NavigationBar
/// ═══════════════════════════════════════
/// Shell untuk 3 tab utama: Home, Fun Facts, Leaderboard.
/// Tab di-handle via go_router ShellRoute, jadi state masing-masing
/// tab tetap independent saat berpindah.

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = <_TabSpec>[
    _TabSpec(
      path: '/home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _TabSpec(
      path: '/fun-facts',
      icon: Icons.auto_stories_outlined,
      activeIcon: Icons.auto_stories_rounded,
      label: 'Fun Facts',
    ),
    _TabSpec(
      path: '/leaderboard',
      icon: Icons.leaderboard_outlined,
      activeIcon: Icons.leaderboard_rounded,
      label: 'Leaderboard',
    ),
  ];

  int _indexFor(String location) {
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexFor(location);

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppColors.bgMid,
          indicatorColor: AppColors.primary.withValues(alpha: 0.18),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              color: selected ? AppColors.primary : AppColors.textLo,
              fontSize: 11.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected ? AppColors.primary : AppColors.textLo,
              size: 24,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (i) => context.go(_tabs[i].path),
          destinations: [
            for (final t in _tabs)
              NavigationDestination(
                icon: Icon(t.icon),
                selectedIcon: Icon(t.activeIcon),
                label: t.label,
              ),
          ],
        ),
      ),
    );
  }
}

class _TabSpec {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _TabSpec({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
