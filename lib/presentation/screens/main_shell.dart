import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/ui_language_provider.dart';

/// ═══════════════════════════════════════
/// MAIN SHELL — JumPedia NavigationBar
/// ═══════════════════════════════════════
/// Shell untuk 3 tab utama: Home, Fun Facts, Leaderboard.
/// Tab di-handle via go_router ShellRoute, jadi state masing-masing
/// tab tetap independent saat berpindah.

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _paths = ['/home', '/fun-facts', '/leaderboard'];

  int _indexFor(String location) {
    for (var i = 0; i < _paths.length; i++) {
      if (location.startsWith(_paths[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(uiStringsProvider);
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexFor(location);

    final tabs = <_TabSpec>[
      _TabSpec(
        path: '/home',
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: s.home,
      ),
      _TabSpec(
        path: '/fun-facts',
        icon: Icons.auto_stories_outlined,
        activeIcon: Icons.auto_stories_rounded,
        label: s.funFacts,
      ),
      _TabSpec(
        path: '/leaderboard',
        icon: Icons.leaderboard_outlined,
        activeIcon: Icons.leaderboard_rounded,
        label: s.leaderboard,
      ),
    ];

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
          onDestinationSelected: (i) => context.go(tabs[i].path),
          destinations: [
            for (final t in tabs)
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
